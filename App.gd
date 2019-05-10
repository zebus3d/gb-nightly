extends Control

var current_os = OS.get_name()
var download_link = ''
var file_name = ''
var file_name_prefix = 'blender-2.80'
var file_ext = ''
var date = ''
var up_to_date = false
var blender_hash = ''
var button_clicked = false
var links_ready = false
var presel = 0
var matchRuleLinux64 = ""
var matchRuleLinux32 = ""
var matchRuleWindow64 = ""
var matchRuleWindow32 = ""
var matchRuleMac64 = ""


func getUrl():
	print("obteniendo la url")
	#print($OSSelector.text)
	#print($SystemSelector.text)
	var architecture = $SystemSelector.text
	
	# nombres de versiones:
	#blender-2.80-427c75e4c20b-linux-glibc224-x86_64.tar.bz2
	#blender-2.80-427c75e4c20b-linux-glibc224-i686.tar.bz2
	#blender-2.80-6ef48b13186c-win64.zip
	#blender-2.80-e2d04229c38b-win32.zip
	#blender-2.80-3dc9da3a74ee-OSX-10.9-x86_64.zip
	
#	if $OSSelector.text == 'Linux':
#		if architecture == 'x64':
#			matchRule = ".*(blender-2.80-)([0-9a-zA-Z]*)(-linux-glibc224-x86_64.tar.bz2).*"
#		elif architecture == 'x32':
#			matchRule = ".*(blender-2.80-)([0-9a-zA-Z]*)(-linux-glibc224-i686.tar.bz2).*"
#
#	if $OSSelector.text == 'Windows':
#		if architecture == 'x64':
#			matchRule = ".*(blender-2.80-)([0-9a-zA-Z]*)(-win64.zip).*"
#		elif architecture == 'x32':
#			matchRule = ".*(blender-2.80-)([0-9a-zA-Z]*)(-win32.zip).*"
#
#	if $OSSelector.text == 'Mac':
#		matchRule = ".*(blender-2.80-)([0-9a-zA-Z]*)(-OSX-10.9-x86_64.zip).*"
	
	matchRuleLinux64 = ".*(blender-2.80-)([0-9a-zA-Z]*)(-linux-glibc224-x86_64.tar.bz2).*"
	matchRuleLinux32 = ".*(blender-2.80-)([0-9a-zA-Z]*)(-linux-glibc224-i686.tar.bz2).*"
	matchRuleWindow64 = ".*(blender-2.80-)([0-9a-zA-Z]*)(-win64.zip).*"
	matchRuleWindow32 = ".*(blender-2.80-)([0-9a-zA-Z]*)(-win32.zip).*"
	matchRuleMac64 = ".*(blender-2.80-)([0-9a-zA-Z]*)(-OSX-10.9-x86_64.zip).*"
	
	$HTTPRequest.request("https://builder.blender.org/download/")

func _disable_arch(pesel, condition):
	$SystemSelector.select(presel)
	$SystemSelector.disabled = condition

func _ready():
	match current_os:
		"Windows":
			$OSSelector.select(0)
			file_ext = ".zip"
			_disable_arch($SystemSelector.selected, false)
		"OSX":
			$OSSelector.select(1)
			file_ext = ".zip"
			_disable_arch(0, true)
		"X11":
			$OSSelector.select(2)
			file_ext = ".tar.bz2"
			_disable_arch($SystemSelector.selected, false)


	# Add the date and extension to the file name to compare to previous versions
	date = OS.get_date(true)
	date = str(date['day']) + '-' + str(date['month']) + '-' + str(date['year'])
	_update_file_name()
	

	$ProgressBar.value = 0
	up_to_date = is_up_to_date()
	
	getUrl()
	

func is_up_to_date():
	# Check if the daily zip already exists on our system
	var dir = Directory.new()
	var full_path = OS.get_user_data_dir() + '/' + file_name 
	if dir.file_exists(full_path):
		$DownloadButton.text = "Open Directory"
		$DownloadButton.disabled = false
		return true
	else:
		return false

func update_download_link():
	var architecture = $SystemSelector.text
	if blender_hash:
		
		if $OSSelector.text == 'Windows':
			if architecture == 'x64':
				download_link = 'https://builder.blender.org/download/blender-2.80-'+str(blender_hash)+'-win64.zip'	
			else:
				download_link = 'https://builder.blender.org/download/blender-2.80-'+str(blender_hash)+'-win32.zip'				
		
		elif $OSSelector.text == 'Mac':
			download_link = 'https://builder.blender.org/download/blender-2.80-'+str(blender_hash)+'-OSX-10.9-x86_64.zip'
		
		elif $OSSelector.text == 'Linux':
			if architecture == 'x64':
				download_link = 'https://builder.blender.org/download/blender-2.80-'+str(blender_hash)+'-linux-glibc224-x86_64.tar.bz2'
			else:
				download_link = 'https://builder.blender.org/download/blender-2.80-'+str(blender_hash)+'-linux-glibc224-i686.tar.bz2'
		
		print('Download link: ', download_link)
		links_ready = true
	else:
		print('Blender hash is void!')
		links_ready = false

func _on_AboutButton_pressed():
	$AboutDialog.popup()


func _on_OSSelector_item_selected(ID):
	match ID:
		0:
			file_ext = ".zip"
			_disable_arch($SystemSelector.selected, false)
		1:
			file_ext = ".zip"
			_disable_arch(0, true)
		2:
			file_ext = ".tar.bz2"
			_disable_arch($SystemSelector.selected, false)
	
	getUrl()
	#update_download_link()


func _on_SystemSelector_item_selected(_ID):
	update_download_link()
	up_to_date = false


func _on_DownloadButton_pressed():
	button_clicked = true
	if links_ready:
		_update_file_name()
		var file_path = "user://" + file_name
		
		if up_to_date:
			# It would be nice to open the downloaded file directly
			# but I've been having a lot of issues doing this so
			# I think that opening the container dir is enough for now
			OS.shell_open(OS.get_user_data_dir())
		else:
			# No file found here so we can go ahead and download
			# the latest version
			print("Starting download in:")
			$DownloadButton.disabled = true
			$DownloadButton.text = "Downloading..."
			# Checking if a previous version exists and removing them
			print(OS.get_user_data_dir())
			#print(list_files_in_directory(OS.get_user_data_dir()))
			var dir = Directory.new()
			for file in list_files_in_directory(OS.get_user_data_dir()):
				if 'blender-2.80' in file:
					dir.remove('user://' + file)
				
			# Downloading file
			$HTTPRequest.set_download_file(file_path)
			$HTTPRequest.request(download_link)
			#print($HTTPRequest.get_body_size())
	else:
		print("links not are ready!")

func _process(_delta):
	var size = 0
	var current = 0
	if $HTTPRequest.get_body_size() != -1:
		size = $HTTPRequest.get_body_size()
		current = $HTTPRequest.get_downloaded_bytes()
		$ProgressBar.value = current*100/size
		
	if links_ready:
		$DownloadButton.disabled = false
	else:
		$DownloadButton.disabled = true
		
#func _on_HTTPRequest_request_completed(result, response_code, headers, body):
func _on_HTTPRequest_request_completed(result, response_code, _headers, _body):
	
	# si se hace click al boton descarga que no vuelva
	# a comprobar las urls porque ya deberian estar
	# procesadas anteriormente:
	if button_clicked == false:
		# regex:
		print("procesando el regex")
		var all = _body.get_string_from_utf8()
		
		var regex = RegEx.new()
		var matchrules = [matchRuleLinux64, matchRuleLinux32, matchRuleWindow64, matchRuleWindow32, matchRuleMac64]
		
		for i in range(len(matchrules)):
			regex.compile(matchrules[i])
			var regex_match = regex.search(all)
			if regex_match:
				blender_hash = regex_match.get_string(2)
				matchrules[i] = regex_match.get_string(2)
				print("match!")
				print(blender_hash)
			else:
				print("no se encontro el regex")
		
		print(matchrules[1])
		if blender_hash:
			update_download_link()
	
	# si se hace click en el boton y los enlaces estan listos:
	if button_clicked == true and links_ready == true:
		print("Download completed ", result, ", ", response_code)
		var cwd = OS.get_user_data_dir()
		if current_os == "Windows":
			# Unzip file
			var _command = OS.execute("unzip.exe", [cwd + '/' + file_name, '-d', cwd], true)
			OS.execute("mv", [cwd + '/godot.exe', cwd + '/godot-nightly.exe'], true)
			up_to_date = is_up_to_date()
			# Open the dir
			OS.shell_open(OS.get_user_data_dir())
		elif current_os == "X11":
			print("descomprimiendo en linux")
			print("en: ")
			print(cwd)
			print(file_name)
			OS.execute('/bin/tar jxf', [cwd + '/' + file_name], false)
			OS.execute('/usr/bin/chmod', ['+x', cwd + '/' + file_name], false)
			up_to_date = is_up_to_date()
			OS.shell_open(OS.get_user_data_dir())
		else:
			print('Todo on osx')
		button_clicked = false

func list_files_in_directory(path):
	# By volzhs
	# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
    var files = []
    var dir = Directory.new()
    dir.open(path)
    dir.list_dir_begin()

    while true:
        var file = dir.get_next()
        if file == "":
            break
        elif not file.begins_with("."):
            files.append(file)

    dir.list_dir_end()

    return files

func _on_Label2_meta_clicked(meta):
	OS.shell_open(meta)


func _on_Warning_meta_clicked(meta):
	OS.shell_open(meta)
	
func _update_file_name():
	file_name = file_name_prefix + '-' + date + file_ext
