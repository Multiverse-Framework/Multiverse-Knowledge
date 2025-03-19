from knowrob import *

InitKnowRob()

kb = KnowledgeBase("/home/sascha/workspace/multiverse_krr/Multiverse-Knowledge/knowrob_connector/settings/multiverse.json")

def runQuery(queryStr):
    phi = QueryParser.parse(queryStr)
    resultStream = kb.submitQuery(phi, QueryContext(QueryFlag.QUERY_FLAG_ALL_SOLUTIONS))
    resultQueue = resultStream.createQueue()
    retq = None
    result = resultQueue.pop_front()
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

res = runQuery("position(someobject, ?x)")

print(str(res))