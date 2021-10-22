import json

def jsonSerializer(object_list_serializer):
    serialized_json = []
    for json_to_serialize in object_list_serializer:
        serialized_json.append('{ "UserName "' + ':"' + str(json_to_serialize.UserName) + '",' + '"ID" ' + ':' + str(json_to_serialize.ID) + "},")
    last_elem = serialized_json[-1]
    serialized_json.pop(-1)
    serialized_json.append(last_elem[:-1])
    return serialized_json