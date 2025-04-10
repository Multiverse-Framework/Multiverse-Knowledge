#include <knowrob/reasoner/RDFGoalReasoner.h>
#include <knowrob/reasoner/RDFGoal.h>
#include <knowrob/terms/ListTerm.h>
#include <multiverse_client_json.h>

#include <map>
#include <set>

std::map<std::string, size_t> attribute_map_double = {
    {"", 0},
    {"time", 1},
    {"position", 3},
    {"quaternion", 4},
    {"relative_velocity", 6},
    {"odometric_velocity", 6},
    {"joint_rvalue", 1},
    {"joint_tvalue", 1},
    {"joint_linear_velocity", 1},
    {"joint_angular_velocity", 1},
    {"joint_linear_acceleration", 1},
    {"joint_angular_acceleration", 1},
    {"joint_force", 1},
    {"joint_torque", 1},
    {"cmd_joint_rvalue", 1},
    {"cmd_joint_tvalue", 1},
    {"cmd_joint_linear_velocity", 1},
    {"cmd_joint_angular_velocity", 1},
    {"cmd_joint_force", 1},
    {"cmd_joint_torque", 1},
    {"joint_position", 3},
    {"joint_quaternion", 4},
    {"force", 3},
    {"torque", 3}};

// list of supported properties
std::set<std::string> supported_properties = {
    "position",
    "quaternion"};

class MultiverseKnowRobConnector : public MultiverseClientJson
{
public:
    MultiverseKnowRobConnector(
        const std::string &world_name,
        const std::string &simulation_name,
        const std::string &in_host,
        const std::string &in_server_port,
        const std::string &in_client_port)
    {
        meta_data["world_name"] = world_name;
        meta_data["simulation_name"] = simulation_name;
        meta_data["length_unit"] = "m";
        meta_data["angle_unit"] = "rad";
        meta_data["mass_unit"] = "kg";
        meta_data["time_unit"] = "s";
        meta_data["handedness"] = "rhs";

        host = in_host;
        server_port = in_server_port;
        client_port = in_client_port;

        receive_objects = {
            {"", {"position", "quaternion"}}};

        connect();

        *world_time = 0.0;

        reset();

        KB_INFO("MultiverseKnowRobConnector initialized with"
                ": world_name: " + world_name +
                ", simulation_name: " + simulation_name +
                ", host: " + host +
                ", server_port: " + server_port +
                ", client_port: " + client_port + "\n");

        // create mockup data
        // Initialize member arrays instead of local ones
        // position_1[0] = 1.0; position_1[1] = 2.0; position_1[2] = 3.0;
        // position_2[0] = 3.0; position_2[1] = 4.0; position_2[2] = 5.0;
        // quaternion_1[0] = 1.3; quaternion_1[1] = 1.0; quaternion_1[2] = 2.0; quaternion_1[3] = 3.0;
        // quaternion_2[0] = 1.3; quaternion_2[1] = 3.0; quaternion_2[2] = 4.0; quaternion_2[3] = 5.0;

        // receive_objects_data = {
        //     {"object1",
        //      {{"position", {&position_1[0], &position_1[1], &position_1[2]}},
        //       {"quaternion", {&quaternion_1[0], &quaternion_1[1], &quaternion_1[2], &quaternion_1[3]}}}},
        //     {"object2",
        //      {{"position", {&position_2[0], &position_2[1], &position_2[2]}},
        //       {"quaternion", {&quaternion_2[0], &quaternion_2[1], &quaternion_2[2], &quaternion_2[3]}}}}};
    }

    ~MultiverseKnowRobConnector()
    {
    }

public:
    std::map<std::string, std::map<std::string, std::vector<double *>>> get_receive_objects_data() const
    {
        return receive_objects_data;
    }

    void start()
    {
        communicate(true);
        communicate();
        communication_thread = std::thread([this]()
                                           {
            while (!stop_thread)
            {
                KB_INFO("Communicating with server...");
                if (!communicate())
                {
                    break;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(1000));
            } });
        KB_INFO("Started MultiverseKnowRobConnector");
    }

    void stop()
    {
        stop_thread = true;
        if (communication_thread.joinable())
        {
            communication_thread.join();
        }
    }

private:
    void start_connect_to_server_thread() override
    {
        connect_to_server();
    }

    void wait_for_connect_to_server_thread_finish() override
    {
    }

    void start_meta_data_thread() override
    {
        send_and_receive_meta_data();
    }

    void wait_for_meta_data_thread_finish() override
    {
    }

    bool init_objects(bool) override
    {
        return send_objects.size() > 0 || receive_objects.size() > 0;
    }

    void bind_request_meta_data() override
    {
        // Create JSON object and populate it
        request_meta_data_json.clear();
        request_meta_data_json["meta_data"]["world_name"] = meta_data["world_name"];
        request_meta_data_json["meta_data"]["simulation_name"] = meta_data["simulation_name"];
        request_meta_data_json["meta_data"]["length_unit"] = meta_data["length_unit"];
        request_meta_data_json["meta_data"]["angle_unit"] = meta_data["angle_unit"];
        request_meta_data_json["meta_data"]["mass_unit"] = meta_data["mass_unit"];
        request_meta_data_json["meta_data"]["time_unit"] = meta_data["time_unit"];
        request_meta_data_json["meta_data"]["handedness"] = meta_data["handedness"];

        for (const std::pair<const std::string, std::set<std::string>> &send_object : send_objects)
        {
            for (const std::string &attribute_name : send_object.second)
            {
                request_meta_data_json["send"][send_object.first].append(attribute_name);
            }
        }

        for (const std::pair<const std::string, std::set<std::string>> &receive_object : receive_objects)
        {
            for (const std::string &attribute_name : receive_object.second)
            {
                request_meta_data_json["receive"][receive_object.first].append(attribute_name);
            }
        }

        request_meta_data_str = request_meta_data_json.toStyledString();
    }

    void bind_response_meta_data() override
    {
        KB_INFO("Received meta data from server: " + response_meta_data_str);

        send_objects.clear();
        for (const std::string &object_name : response_meta_data_json["send"].getMemberNames())
        {
            send_objects[object_name] = {};
            for (const std::string &attribute_name : response_meta_data_json["send"][object_name].getMemberNames())
            {
                send_objects[object_name].insert(attribute_name);
            }
        }

        receive_objects.clear();
        for (const std::string &object_name : response_meta_data_json["receive"].getMemberNames())
        {
            receive_objects[object_name] = {};
            for (const std::string &attribute_name : response_meta_data_json["receive"][object_name].getMemberNames())
            {
                receive_objects[object_name].insert(attribute_name);
            }
        }
    }

    void bind_api_callbacks() override
    {
    }

    void bind_api_callbacks_response() override
    {
    }

    void init_send_and_receive_data() override
    {
        double *send_buffer_double = send_buffer.buffer_double.data;
        for (const std::pair<const std::string, std::set<std::string>> &send_object : send_objects)
        {
            send_objects_data[send_object.first] = {};
            for (const std::string &attribute_name : send_object.second)
            {
                send_objects_data[send_object.first][attribute_name] = {};
                for (size_t i = 0; i < attribute_map_double[attribute_name]; ++i)
                {
                    send_objects_data[send_object.first][attribute_name].emplace_back(send_buffer_double++);
                }
            }
        }

        double *receive_buffer_double = receive_buffer.buffer_double.data;
        for (const std::pair<const std::string, std::set<std::string>> &receive_object : receive_objects)
        {
            receive_objects_data[receive_object.first] = {};
            for (const std::string &attribute_name : receive_object.second)
            {
                receive_objects_data[receive_object.first][attribute_name] = {};
                for (size_t i = 0; i < attribute_map_double[attribute_name]; ++i)
                {
                    receive_objects_data[receive_object.first][attribute_name].emplace_back(receive_buffer_double++);
                }
            }
        }
    }

    void bind_send_data() override
    {
        *world_time = get_time_now() - sim_start_time;
    }

    void bind_receive_data() override
    {
    }

    void clean_up() override
    {
        send_objects_data.clear();
        receive_objects_data.clear();
    }

    void reset() override
    {
        sim_start_time = get_time_now();
    }

private:
    std::map<std::string, std::string> meta_data;

    std::map<std::string, std::set<std::string>> send_objects;

    std::map<std::string, std::set<std::string>> receive_objects;

    std::map<std::string, std::map<std::string, std::vector<double *>>> send_objects_data;

    std::map<std::string, std::map<std::string, std::vector<double *>>> receive_objects_data;

    double sim_start_time;

    std::thread communication_thread;

    bool stop_thread = false;

    // double position_1[3];
    // double position_2[3];
    // double quaternion_1[4];
    // double quaternion_2[4];
};

class MultiverseReasoner : public knowrob::RDFGoalReasoner
{
public:
    MultiverseReasoner(std::string_view)
    {
        // Use all elements of supported_properties to define relations
        for (const std::string &property : supported_properties)
        {
            defineRelation(knowrob::PredicateIndicator(property, 2));
        }
    }

    ~MultiverseReasoner()
    {
        if (connector != nullptr)
        {
            connector->stop();
            delete connector;
        }
    }

    bool initializeReasoner(const knowrob::PropertyTree &ptree)
    {
        // Get the world_name, simulation_name, host, server_port, and client_port from the ptree, default values should be null
        auto world_name = ptree->get_optional<std::string>("world_name");
        auto simulation_name = ptree->get_optional<std::string>("simulation_name");
        auto host = ptree->get_optional<std::string>("host");
        auto server_port = ptree->get_optional<std::string>("server_port");
        auto client_port = ptree->get_optional<std::string>("client_port");
        // Check if any of the values are empty, print individual error messages and return false
        if (!world_name.has_value())
        {
            KB_ERROR("world_name is not set");
            return false;
        }
        if (!simulation_name.has_value())
        {
            KB_ERROR("simulation_name is not set");
            return false;
        }
        if (!host.has_value())
        {
            KB_ERROR("host is not set");
            return false;
        }
        if (!server_port.has_value())
        {
            KB_ERROR("server_port is not set");
            return false;
        }
        if (!client_port.has_value())
        {
            KB_ERROR("client_port is not set");
            return false;
        }

        // Create the MultiverseKnowRobConnector object, using std_unique_ptr
        connector = new MultiverseKnowRobConnector(world_name.value(), simulation_name.value(), host.value(), server_port.value(), client_port.value());
        connector->start();
        return true;
    }

    bool evaluate(knowrob::RDFGoalPtr goal)
    {
        auto literal = goal->rdfLiterals().at(0);
        knowrob::TermPtr s = literal->subjectTerm();
        knowrob::TermPtr o = literal->objectTerm();
        knowrob::TermPtr p = literal->propertyTerm();
        // Check if subject is a atom and object is a literal
        if (s->isAtomic() && p->isAtomic() && o->isVariable())
        {
            // Get var of subject
            auto s_atomic = std::static_pointer_cast<knowrob::Atomic>(s);
            // s_atomic->stringForm() to get string
            // Get var of object
            auto o_var = std::static_pointer_cast<knowrob::Variable>(o);
            // Check value of property is position
            auto p_atomic = std::static_pointer_cast<knowrob::Atomic>(p);
            // Check if the object is in get_receive_objects_data
            auto receive_objects_data = connector->get_receive_objects_data();
            if (receive_objects_data.find(std::string(s_atomic->stringForm())) == receive_objects_data.end())
            {
                return false;
            }
            // Check if the property is in the receive_objects_data
            auto object_it = receive_objects_data.find(std::string(s_atomic->stringForm()));
            if (object_it == receive_objects_data.end() || object_it->second.find(std::string(p_atomic->stringForm())) == object_it->second.end())
            {
                return false;
            }
            // Get the data from the receive_objects_data
            auto data = receive_objects_data[std::string(s_atomic->stringForm())][std::string(p_atomic->stringForm())];
            // Create xsdatomics for all the values, then a listterm containing them
            // Create xsdatomic for all the values using the create function
            std::vector<knowrob::TermPtr> terms;
            for (double *value : data)
            {
                auto x = knowrob::XSDAtomic::create(std::to_string(*value), "http://www.w3.org/2001/XMLSchema#double");
                terms.push_back(x);
            }
            // Create listterm using the terms
            auto result_list = std::make_shared<knowrob::ListTerm>(terms);

            // Create bindings
            auto bindings = std::make_shared<knowrob::Bindings>();
            // Bind the data to the object and attribute
            bindings->set(o_var, result_list);
            // Return the bindings
            goal->push(bindings);
        }
        return true;
    }

private:
    MultiverseKnowRobConnector *connector = nullptr;
};

// define the plugin
REASONER_PLUGIN(MultiverseReasoner, "MultiverseReasoner");