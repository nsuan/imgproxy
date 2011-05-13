<?php

//this is the only thing you need to configure:
$dir = '/tmp/i/';

header("Expires: " . gmdate("D, d M Y H:i:s", time() + 86400) . " GMT");
header("Cache-Control: max-age=604800, must-revalidate");

$url = $_SERVER['REQUEST_URI'];
$url[0] = ' ';
$url[1] = ' ';
$url[2] = ' ';
$url = trim($url);
$f_dir = $dir;
if(!file_exists($dir))
	mkdir($dir);
	
//hash the URL
$md5 = $urlhash = md5($url);
$sfile = $_SERVER['PATH_INFO'];

//figure out where the image file is
$path = $dir . $md5[0] . '/' .  $md5[1] . '/' .  $md5[2] . '/' .  $md5[3] . '/';
mkdir($path, 0766, true);
if(file_exists($dir . $sfile))  {
	$urlhash = $sfile;
	if(stripos($url, '://') !== FALSE) 
		header("Location: /i/" . $sfile);
		
} else {
	$dir = $path;
}

$cached = false;

if(file_exists($dir . $urlhash)) {
	$arr = unserialize(file_get_contents($dir . $urlhash));
	$file = $arr['file'];
	$content  = $arr['content'];
	if($content != '')
		$cached = true;
	error_log("cached");
}

if(!file_exists($dir . $urlhash) || $cached != true) {
	//not cached, gotta download it.
	$agent = "Mozilla/5.0 (X11; U; Linux i586; en-US; rv:1.7.5) Gecko/20041111 Fireyiff/1.0.7";
	$ch = curl_init(str_replace(' ', '%20', $url));
	curl_setopt($ch, CURLOPT_HEADERFUNCTION, 'read_header');
	curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);
	curl_setopt($ch, CURLOPT_USERAGENT, $agent);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
	$file = curl_exec($ch);
	if(curl_errno($ch))
		error_log('error:' . curl_error($ch));
		
		
	//verify this is actually an image.
	if(stripos($content,'image') === false && stripos($content,'audio') === false)
		die();
		
		
	//store data in the cache
	$arr['file'] = $file;
	$arr['content'] = $content;
	file_put_contents($dir . $urlhash, serialize($arr));
	error_log($url . " " . $urlhash . "$dir new");
	error_log($url . " $f_dir/$sfile");
	if(symlink($dir. $urlhash, $f_dir . '/' . $sfile)) {
		header("Location: /i/" . $sfile);
	}
} else {
	//pull image and header data from the cache 
	$arr = unserialize(file_get_contents($dir . $urlhash));
	$file = $arr['file'];
	$content  = $arr['content'];
	error_log($url . " " . $urlhash . " cached");
}

//if the browser thinks the file is cached we assume it's correct.
if(isset($_SERVER['HTTP_IF_NONE_MATCH'])  || isset($_SERVER['HTTP_IF_MODIFIED_SINCE'])) {
	header('HTTP/1.0 304 Not Modified');
	exit;
}

//prepare headers and send file
header($content);
header("Content-Length: " . strlen($file));
$last_modified = substr(date('r', filemtime($dir . $urlhash)), 0, -5).'GMT';
header("Last-Modified: $last_modified");
header("ETag: " . $urlhash);
echo $file;

function read_header($ch, $string) {
    global $content;
    $length = strlen($string);
    if(substr($string,0,strlen('Content-Type:')) == 'Content-Type:') {
		$content = $string;
    }
    return $length;
}
?>

