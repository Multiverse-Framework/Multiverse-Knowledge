from knowrob import *

InitKnowRob()

kb = KnowledgeBase("/home/sascha/workspace/multiverse_krr/Multiverse-Knowledge/knowrob_connector/settings/multiverse.json")

def runQuery(queryStr):
    phi = QueryParser.parse(queryStr)
    resultStream = kb.submitQuery(phi, QueryContext(QueryFlag.QUERY_FLAG_ALL_SOLUTIONS))
    resultQueue = resultStream.createQueue()
    retq = None
    result = resultQueue.pop_front()
    # print if indicatesEndOfEvaluation() is False
    print("indicatesEnd is " + str(result.indicatesEndOfEvaluation()))
    while not result.indicatesEndOfEvaluation():
        if retq is None:
            retq = []
        if isinstance(result, AnswerYes):
            aux = {}
            for substitution in result.substitution():
                variable, term = substitution[1], substitution[2]
                svar, sterm = None, None
                try:
                    svar, sterm = str(variable), str(term)
                except:
                    pass
                if (svar is not None) and (sterm is not None):
                    aux[svar] = str(sterm)
            retq.append(aux)
        elif isinstance(result, AnswerNo):
            retq = None
            break
        result = resultQueue.pop_front()
    return retq

# Write tests for this mockup data (fail if not working)

# Query position and quaternion of object1
res = runQuery("position(object1, ?x), quaternion(object1, ?y)")
print(str(res))
# unit test for the above query
assert res is not None
assert len(res) == 2
assert res["P"][0] == 1.0
assert res["P"][1] == 2.0
assert res["P"][2] == 3.0

# Query only position of object2
res = runQuery("position(object2, P)")
# unit test for the above query
assert res is not None
assert len(res) == 1
assert res["P"][0] == 3.0
assert res["P"][1] == 4.0
assert res["P"][2] == 5.0

# Query only quaternion of object2
res = runQuery("quaternion(object2, Q)")
# unit test for the above query
assert res is not None
assert len(res) == 1
assert res["Q"][0] == 1.3
assert res["Q"][1] == 3.0
assert res["Q"][2] == 4.0
assert res["Q"][3] == 5.0

# Query for non-existing object
res = runQuery("position(object3, P)")
# unit test for the above query
assert res is None

# Query for non-existing attribute
res = runQuery("midichlorian_count(object1, Q)")
# unit test for the above query
assert res is None