#include <knowrob/knowrob.h>
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
    }

    ~MultiverseKnowRobConnector()
    {

    }

public:
    std::vector<double *> get_receive_object_data(const std::string &object_name, const std::string &attribute_name)
    {
        if (receive_objects_data.find(object_name) == receive_objects_data.end())
        {
            printf("Object %s not found\n", object_name.c_str());
            return {};
        }
        if (receive_objects_data[object_name].find(attribute_name) == receive_objects_data[object_name].end())
        {
            printf("Attribute %s not found\n", attribute_name.c_str());
            return {};
        }
        return receive_objects_data[object_name][attribute_name];
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
};