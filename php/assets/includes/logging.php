<?php

  function LogDebug($msg, $display = true)
  {
    global $debug, $logfile;
    if ($display and $debug) {
      fwrite($logfile, $msg."\n");
    }
  }

  function LogError($msg, $code = 1)
  {
    global $quiet;
    if (!$quiet) {
      PrintLine($msg);
    }
    exit($code);
  }

  function LogInfo($msg, $progress = false)
  {
    global $quiet;
    if (!$quiet) {
      PrintLine($msg, $progress);
    }
  }

  function PrintLine($msg, $progress = false)
  {
    if ($msg) {
      printf("\r%-79s\r", "");
      if ($progress) {
        printf("%s\r", $msg);
      } else {
        printf("%s\n", $msg);
      }
    } else {
      printf("\n");
    }
  }

?>
