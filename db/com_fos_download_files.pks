create or replace package com_fos_download_files
as

    function execution
      ( p_process in apex_plugin.t_process
      , p_plugin  in apex_plugin.t_plugin
      )
    return apex_plugin.t_process_exec_result;

end;
/


