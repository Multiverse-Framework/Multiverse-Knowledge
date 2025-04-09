from knowrob import *
import json

InitKnowRob()

kb = KnowledgeBase("settings/multiverse.json")

def runQuery(queryStr):
    phi = QueryParser.parse(queryStr)
    resultStream = kb.submitQuery(phi, QueryContext(QueryFlag.QUERY_FLAG_ALL_SOLUTIONS))
    resultQueue = resultStream.createQueue()
    retq = None
    result = resultQueue.pop_front()
    # print if indicatesEndOfEvaluation() is False
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
res = runQuery("position(object1, P), quaternion(object1, Q)")
# Create a List of doubles from the string using json loads
positionList1 = json.loads(res[0]["P"])
quaternionList1 = json.loads(res[0]["Q"])
# unit test for the above query
assert positionList1[0] == 1.0  
assert positionList1[1] == 2.0  
assert positionList1[2] == 3.0  
assert quaternionList1[0] == 1.3
assert quaternionList1[1] == 1.0
assert quaternionList1[2] == 2.0
assert quaternionList1[3] == 3.0

# Query only position of object2
res = runQuery("position(object2, P)")
# Create a List of doubles from the string using json loads
positionList2 = json.loads(res[0]["P"])
# print the result of the query
print(str(positionList2))
# unit test for the above query
assert positionList2[0] == 3.0
assert positionList2[1] == 4.0
assert positionList2[2] == 5.0

# Query only quaternion of object2
res = runQuery("quaternion(object2, Q)")
# Create a List of doubles from the string using json loads
quaternionList2 = json.loads(res[0]["Q"])
# unit test for the above query
assert quaternionList2[0] == 1.3
assert quaternionList2[1] == 3.0
assert quaternionList2[2] == 4.0
assert quaternionList2[3] == 5.0

# Query for non-existing object
#res = runQuery("position(object3, P)")
# unit test for the above query
#assert res is None

# Query for non-existing attribute
# TODO: Check why this is not working
# res = runQuery("midichlorian_count(object1, Q)")
# unit test for the above query
# assert res is []
