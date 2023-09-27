extends Node2D

var auth_token
onready var http_request_node = $http/httpReq
onready var url_label = $fg/left/url_label
onready var url_textbox = $fg/left/url
onready var auth_textbox = $fg/left/auth_token
onready var auth_token_label = $fg/left/auth_label
onready var init_comment_textbox = $fg/left/init_comment
onready var changed_comment_textbox = $fg/left/changed_comment
onready var comment_id_textbox = $fg/right/comment_id
onready var scope_api = $fg/right/scope
onready var oauth_url = $fg/right/oauth
onready var auth_token_timer = $misc/auth_token_timer
onready var videos_array_textbox = $fg/right/videos_array
onready var video_timer = $misc/video_timer
var videos_array = []
var valid_auth = false
var check_video_url = "http://hsm.ugatu.su/yt/wtload.php?videoId="
var is_http_ready = true
var saved_video_id
var saved_comment_id
var saved_json
var is_json = true
var is_started = false
var state = "not wathcing"
var duration_of_video
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	auth_token = auth_textbox.text
	if auth_token_timer.time_left != 0:
		auth_token_label.text = "AUTH TOKEN | WAIT TIME: "+str(int(auth_token_timer.time_left))
	if !videos_array.empty() and is_started and state == "ready to watch":
		getVideo(videos_array[0])
		saved_video_id = videos_array[0]
		state = "getting video"
	if state == "got video":
		duration_of_video = durationToSeconds(getVideoDuration(saved_json))
		initCommentAndVideo(videos_array[0])
		state = "commenting video"
	if state == "commented video":
		saved_comment_id = getCommentId(saved_json)
		state = "wathing"
		video_timer.start(duration_of_video)
		videos_array.remove(0)
	if state == "editted comment":
		checkVideo(saved_video_id)
		state = "checking comment"
	if state == "checked comment":
		state = "ready to watch"
	if state == "wathing":
		url_label.text = "URL: "+str(saved_video_id)+" TL: "+str(video_timer.time_left)
	else:
		url_label.text = "URL: "+state
	if videos_array.empty() and state == "ready to watch":
		state = "not wathcing"
	pass


func _on_httpReq_request_completed(result, response_code, _headers, body):
	print(result)
	print(response_code)
	if is_json:
		var json_parsed = JSON.parse(body.get_string_from_utf8())
		var json_result = json_parsed.result
		saved_json = json_result
		print("JSON result: " + str(json_result)+ "END OF JSON RESULT")
	$fg/left/console.text = body.get_string_from_utf8()# https://www.googleapis.com/youtube/v3/commentThreads?key={your_api_key}&textFormat=plainText&part=snippet&videoId={video_id}&maxResults=100&pageToken={nextPageToken}
	# print(body.get_string_from_ascii()) # Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	is_http_ready = true # Replace with function body.
	if state == "getting video":
		state = "got video"
	elif state == "commenting video":
		state = "commented video"
	elif state == "editting comment":
		state = "editted comment"
	elif state == "checking comment":
		state = "checked comment"


func _on_check_url_pressed():
	var id = url_textbox.text.split("=")[1]
	saved_video_id = id
	getVideo(id)
	pass # Replace with function body.


func initCommentAndVideo(video_id):
	if is_http_ready:
		var body_of_request = {"snippet": {"videoId":str(video_id), "topLevelComment": {"snippet":{"textOriginal":init_comment_textbox.text}}}}
		var json_body = JSON.print(body_of_request)
		print(json_body)
		is_json = true
		var _error = http_request_node.request("https://youtube.googleapis.com/youtube/v3/commentThreads?part=snippet",
		["Authorization: Bearer "+auth_token, "Content-Type: application/json", "Accept: application/json"], true, HTTPClient.METHOD_POST, json_body)
		is_http_ready = false
		

func editComment(comment_id):
	if is_http_ready:
		var body_of_request = {"id": str(comment_id), "snippet": {"textOriginal":changed_comment_textbox.text}}
		var json_body = JSON.print(body_of_request)
		print(json_body)
		is_json = true
		var _error = http_request_node.request("https://youtube.googleapis.com/youtube/v3/comments?part=snippet",
		["Authorization: Bearer "+auth_token, "Content-Type: application/json", "Accept: application/json"], true, HTTPClient.METHOD_PUT, json_body)
		is_http_ready = false

func getVideo(video_id):
	if is_http_ready:
		is_json = true
		var _error = http_request_node.request("https://youtube.googleapis.com/youtube/v3/videos?part=snippet%2CcontentDetails%2Cstatistics&id="+str(video_id),
		["Authorization: Bearer "+auth_token, "Accept: application/json"], true,HTTPClient.METHOD_GET)
		is_http_ready = false

func checkVideo(video_id):
	if is_http_ready:
		is_json = false
		var _error = http_request_node.request(check_video_url+str(video_id),[],true,HTTPClient.METHOD_GET)
		is_http_ready = false

func getVideoDuration(json_body):
#	var json_parsed = JSON.parse(json_body.get_string_from_utf8())
#	var json_result = json_parsed.result
	if "items" in json_body:
		return json_body["items"][0]["contentDetails"]["duration"]
	else:
		state = "not watching"
		return null

func getCommentId(json_body):
#	var json_parsed = JSON.parse(json_body.get_string_from_utf8())
#	var json_result = json_parsed.result
	if "id" in json_body:
		return json_body["id"]
	else:
		state = "not watching"
		return null

func _on_comment_it_pressed():
	if saved_video_id:
		initCommentAndVideo(saved_video_id)
	pass # Replace with function body.


func _on_change_comment_pressed():
	if comment_id_textbox.text != "":
		editComment(comment_id_textbox.text)
	pass # Replace with function body.


func _on_scope_text_changed():
	scope_api.text = "https://www.googleapis.com/auth/youtube.force-ssl"
	pass # Replace with function body.


func _on_oauth_text_changed():
	oauth_url.text = "https://developers.google.com/oauthplayground/"
	pass # Replace with function body.


func _on_check_video_pressed():
	if saved_video_id:
		checkVideo(saved_video_id)
	pass # Replace with function body.


func _on_auth_token_text_changed():
	auth_token_timer.start(3600)
	valid_auth = true
	auth_token_label.self_modulate = Color.green
	pass # Replace with function body.


func _on_auth_token_timer_timeout():
	valid_auth = false
	auth_token_label.self_modulate = Color.red
	pass # Replace with function body.


func _on_add_to_array_pressed():
	var id = url_textbox.text.split("=")[1]
	videos_array.append(str(id))
	videos_array_textbox.text = str(videos_array)
	pass # Replace with function body.


func _on_videos_array_text_changed():
	videos_array_textbox.text = str(videos_array)
	pass # Replace with function body.


func _on_video_timer_timeout():
	state = "editting comment"
	editComment(saved_comment_id)
	pass # Replace with function body.


func _on_start_pressed():
	if valid_auth:
		is_started = true
		state = "ready to watch"
	pass # Replace with function body.

func durationToSeconds(duration:String):
	var seconds = 0
	var edited_string = duration.replace("PT","")
	if "H" in edited_string:
		seconds += int(edited_string.split("H")[0])*60*60
		if "M" in edited_string or "S" in edited_string:
			edited_string = edited_string.split("H")[1]
	if "M" in edited_string:
		seconds += int(edited_string.split("M")[0])*60
		if "S" in edited_string:
			edited_string = edited_string.split("M")[1]
	if "S" in edited_string:
		edited_string.replace("S","")
		seconds += int(edited_string)
	return seconds
