<?php 
	error_reporting(E_ALL);
	ini_set('display_errors', 1);

	echo "<h1>Server Connection Information</h1>";
	echo "===> Test MySQL connection...<br />";

	$servername = "mysql";
	$username = "docker";
	$password = "docker";

	echo " hostname: ".$servername."<br />";
	echo " username: ".$username."<br />";
	echo " password: ".$password."<br />";

	// Create connection
	$conn = new mysqli($servername, $username, $password);

	// Check connection
	if ($conn->connect_error) {
	    echo "Connection failed: ". $conn->connect_error."<br />";
	} else {
		echo "Connected successfully<br />";	
	}
	echo "<br />";
	echo "===> Check server info...<br />";
	echo "Server hostname: ".gethostname()."<br />";
	echo "Server address: ".$_SERVER['SERVER_ADDR']."<br />";

#	echo phpinfo();