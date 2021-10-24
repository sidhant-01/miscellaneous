def jsonSerializer(object_list_serializer):
    serialized_json = ""
    for json_to_serialize in object_list_serializer:
        serialized_json += '{ "UserName "' + ':"' + str(json_to_serialize.UserName) + '",' + '"ID" ' + ':' + str(json_to_serialize.ID) + "},"
    serialized_json = serialized_json[:-1]
    return "[" + serialized_json + "]"
