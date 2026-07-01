extends Node


func upnp_setup(port):
	var upnp = UPNP.new()
	var discover = upnp.discover()
	assert(discover == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed error %s" %discover)
	var map_result = upnp.add_port_mapping(port)
	print(upnp.query_external_address())
