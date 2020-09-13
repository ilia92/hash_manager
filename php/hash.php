<!DOCTYPE html>
<html>

<head>
  <title>Mining Checker</title>
</head>

<br>
<form method="post">
    <input type="submit" name="reload" id="reload" value="RELOAD" style="height:60px; width:150px"" /><br/>
</form>
<br>

<?php

function hash_reload()
{
include 'config.php';

ob_start();

$gpu_chk = shell_exec("cd $hash_manager_loc ; bash hash_checker.sh > cache.txt");
shell_exec("chmod 666 $hash_manager_loc/cache.txt 2> /dev/null");

echo "$gpu_chk";

}

if(array_key_exists('reload',$_POST)){
hash_reload();
header("Refresh:0");
}

?>

<?php

include 'config.php';
$cachepage = shell_exec("cat $hash_manager_loc/cache.txt | aha");
echo $cachepage;

?>
