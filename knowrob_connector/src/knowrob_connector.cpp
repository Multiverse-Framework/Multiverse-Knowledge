// #include <knowrob.ccp>
#include <multiverse_client_json.h>

#include <map>
#include <set>

class MultiverseKnowRobConnector : public MultiverseClientJson
{
public:
    ~MultiverseKnowRobConnector()
    {

    }

public:

private:
    void start_connect_to_server_thread() override
    {

    }

    void wait_for_connect_to_server_thread_finish() override
    {

    }

    void start_meta_data_thread() override
    {

    }

    void wait_for_meta_data_thread_finish() override
    {

    }

    bool init_objects(bool from_request_meta_data = false) override
    {
        return true;
    }

    void bind_request_meta_data() override
    {

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

    }

    void bind_send_data() override
    {

    }

    void bind_receive_data() override
    {

    }

    void clean_up() override
    {

    }

    void reset() override
    {

    }

private:
    std::map<std::string, std::string> meta_data;

    std::map<std::string, std::set<std::string>> send_objects;

    std::map<std::string, std::set<std::string>> receive_objects;

    std::vector<double *> send_data_vec;

    std::vector<double *> receive_data_vec;
};