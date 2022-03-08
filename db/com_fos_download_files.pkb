create or replace package body com_fos_download_files
as

-- =============================================================================
--
--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)
--
-- =============================================================================

-- global contants
c_plugin_name constant varchar2(100) := 'FOS - Download File(s)';

-- helper function for converting clob to blob
function clob_to_blob
  ( p_clob    in clob
  )
return blob
as
    l_blob         blob;
    l_clob         clob   := empty_clob();
    l_dest_offset  number := 1;
    l_src_offset   number := 1;
    l_lang_context number := dbms_lob.default_lang_ctx;
    l_warning      number := dbms_lob.warn_inconvertible_char;
begin

    if p_clob is null or dbms_lob.getlength(p_clob) = 0
    then
        dbms_lob.createtemporary
          ( lob_loc => l_clob
          , cache   => true
          );
    else
        l_clob := p_clob;
    end if;

    dbms_lob.createtemporary
      ( lob_loc => l_blob
      , cache   => true
      );

    dbms_lob.converttoblob
      ( dest_lob      => l_blob
      , src_clob      => l_clob
      , amount        => dbms_lob.lobmaxsize
      , dest_offset   => l_dest_offset
      , src_offset    => l_src_offset
      , blob_csid     => dbms_lob.default_csid
      , lang_context  => l_lang_context
      , warning       => l_warning
      );

   return l_blob;
end clob_to_blob;

-- helper function for raising errors
procedure raise_error
  ( p_message in varchar2
  , p0        in varchar2 default null
  , p1        in varchar2 default null
  , p2        in varchar2 default null
    )
as
begin
    raise_application_error(-20001, apex_string.format(c_plugin_name || ' - ' || p_message, p0, p1, p2));
end raise_error;

-- main plug-in entry point
function execution
  ( p_process in apex_plugin.t_process
  , p_plugin  in apex_plugin.t_plugin
  )
return apex_plugin.t_process_exec_result
as
    --attributes
    l_source_type     p_process.attribute_01%type := p_process.attribute_01;
    l_is_mode_plsql   boolean                     := (l_source_type = 'plsql');

    l_sql_query       p_process.attribute_02%type := p_process.attribute_02;
    l_plsql_code      p_process.attribute_03%type := p_process.attribute_03;
    l_archive_name    p_process.attribute_04%type := p_process.attribute_04;
    l_always_zip      boolean                     := (p_process.attribute_15 like '%always-zip%');
    l_disposition     p_process.attribute_15%type := case when p_process.attribute_15 like '%inline-disposition%' then 'inline' else 'attachment' end;

    l_result          apex_plugin.t_process_exec_result;

    -- used by the sql mode
    l_context         apex_exec.t_context;

    l_pos_name        number;
    l_pos_mime        number;
    l_pos_blob        number;
    l_pos_clob        number;

    l_blob_col_exists boolean := false;
    l_clob_col_exists boolean := false;

    l_temp_file_name  varchar2(1000);
    l_temp_mime_type  varchar2(1000);
    l_temp_blob       blob;
    l_temp_clob       clob;

    -- column names expected in the sql mode
    c_alias_file_name constant varchar2(20) := 'FILE_NAME';
    c_alias_mime_type constant varchar2(20) := 'FILE_MIME_TYPE';
    c_alias_blob      constant varchar2(20) := 'FILE_CONTENT_BLOB';
    c_alias_clob      constant varchar2(20) := 'FILE_CONTENT_CLOB';

    -- used by the plsql mode
    c_collection_name constant varchar2(20) := 'FOS_DOWNLOAD_FILES';

    -- both modes
    l_final_file      blob;
    l_final_mime_type varchar2(1000);
    l_final_file_name varchar2(1000);

    l_file_count      number;
    l_zipping         boolean;
begin
    -- debug
    if apex_application.g_debug and substr(:DEBUG,6) >= 6
    then
        apex_plugin_util.debug_process
          ( p_plugin  => p_plugin
          , p_process => p_process
          );
    end if;

    -- creating a sql query based on the collection so we can reuse the logic for the sql mode
    if l_is_mode_plsql
    then
        apex_collection.create_or_truncate_collection(c_collection_name);
        apex_exec.execute_plsql(l_plsql_code);

        l_sql_query := 'select c001    as file_name
                             , c002    as file_mime_type
                             , blob001 as file_content_blob
                             , clob001 as file_content_clob
                          from apex_collections
                         where collection_name = ''' || c_collection_name || ''''
        ;
    end if;

    l_context := apex_exec.open_query_context
                   ( p_location          => apex_exec.c_location_local_db
                   , p_sql_query         => l_sql_query
                   , p_total_row_count   => true
                   );

    l_file_count := apex_exec.get_total_row_count(l_context);

    if l_file_count = 0
    then
        raise_error('At least 1 file must be provided');
    end if;

    -- we zip if there are more than 1 file or if always zip is turned on
    l_zipping := ((l_file_count > 1) or l_always_zip);

    -- result set sanity checks
    begin
        l_pos_name := apex_exec.get_column_position
                        ( p_context     => l_context
                        , p_column_name => c_alias_file_name
                        , p_is_required => true
                        , p_data_type   => apex_exec.c_data_type_varchar2
                        );
    exception
        when others then
            raise_error('A %s column must be defined', c_alias_file_name);
    end;

    begin
        l_pos_mime := apex_exec.get_column_position
                        ( p_context     => l_context
                        , p_column_name => c_alias_mime_type
                        , p_is_required => true
                        , p_data_type   => apex_exec.c_data_type_varchar2
                        );
    exception
        when others then
            raise_error('A %s column must be defined', c_alias_mime_type);
    end;

    -- looping through all columns as opposed to using get_column_position
    -- as get_column_position writes an error to the logs if the column is not found
    -- even if the exception is handled
    l_blob_col_exists := false;
    l_clob_col_exists := false;

    for idx in 1 .. apex_exec.get_column_count(l_context)
    loop
        if apex_exec.get_column(l_context, idx).name = c_alias_blob
        then
            l_pos_blob := idx;
            l_blob_col_exists := true;
        end if;

        if apex_exec.get_column(l_context, idx).name = c_alias_clob
        then
            l_pos_clob := idx;
            l_clob_col_exists := true;
        end if;
    end loop;

    -- raise an error if neither a blob nor a clob source was provided
    if not (l_blob_col_exists or l_clob_col_exists)
    then
        raise_error('Either a %s or a %s column must be defined', c_alias_blob, c_alias_clob);
    end if;

    -- looping through all files
    while apex_exec.next_row(l_context)
    loop

        if l_blob_col_exists
        then
            l_temp_blob := apex_exec.get_blob(l_context, l_pos_blob);
            if l_temp_blob is null
            then
                l_temp_blob := empty_blob();
            end if;
        end if;

        if l_clob_col_exists
        then
            l_temp_clob := apex_exec.get_clob(l_context, l_pos_clob);
            if l_temp_clob is null
            then
                l_temp_clob := empty_clob();
            end if;
        end if;

        l_temp_file_name := apex_exec.get_varchar2(l_context, l_pos_name);
        l_temp_mime_type := apex_exec.get_varchar2(l_context, l_pos_mime);

        -- logic for choosing between the blob an clob
        if    (l_blob_col_exists and not l_clob_col_exists)
           or (l_blob_col_exists and l_clob_col_exists and dbms_lob.getlength(l_temp_blob) > 0)
        then
            if apex_application.g_debug
            then
                apex_debug.message('%s - BLOB - %s bytes', l_temp_file_name, dbms_lob.getlength(l_temp_blob));
            end if;

            if l_zipping
            then
                apex_zip.add_file
                  ( p_zipped_blob => l_final_file
                  , p_file_name   => l_temp_file_name
                  , p_content     => l_temp_blob
                  );
            else
                -- there's only 1 file in the result set
                l_final_file_name := l_temp_file_name;
                l_final_mime_type := l_temp_mime_type;
                l_final_file      := l_temp_blob;
            end if;
        else
            if apex_application.g_debug
            then
                apex_debug.message('%s - CLOB - %s bytes', l_temp_file_name, dbms_lob.getlength(l_temp_clob));
            end if;

            if l_zipping
            then
                apex_zip.add_file
                  ( p_zipped_blob => l_final_file
                  , p_file_name   => l_temp_file_name
                  , p_content     => clob_to_blob(l_temp_clob)
                  );
            else
                -- there's only 1 file in the result set
                l_final_file_name := l_temp_file_name;
                l_final_mime_type := l_temp_mime_type;
                l_final_file      := clob_to_blob(l_temp_clob);
            end if;
        end if;
    end loop;

    apex_exec.close(l_context);

    if l_is_mode_plsql
    then
        apex_collection.delete_collection(c_collection_name);
    end if;

    if l_zipping
    then
        apex_zip.finish(l_final_file);

        if l_file_count = 1 then
            l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, l_temp_file_name || '.zip'));
        else
            l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, 'files.zip'));
        end if;

        l_final_mime_type := 'application/zip';

        if l_final_file_name not like '%.zip'
        then
            l_final_file_name := l_final_file_name || '.zip';
        end if;
    end if;

    sys.htp.init;
    sys.owa_util.mime_header(l_final_mime_type, false);
    sys.htp.p('Content-Length: ' || dbms_lob.getlength(l_final_file));
    sys.htp.p('Content-Disposition: '||l_disposition||'; filename="' || l_final_file_name || '";');
    sys.owa_util.http_header_close;

    sys.wpg_docload.download_file(l_final_file);
    apex_application.stop_apex_engine;

    return l_result;
exception
    -- this is the exception thrown by stop_apex_engine
    -- catching it here so it won't be handled by the others handlers
    when apex_application.e_stop_apex_engine then
        raise;
    when others then
        -- delete the collection in case the error occurred between opening and closing it
        if apex_collection.collection_exists(c_collection_name)
        then
            apex_collection.delete_collection(c_collection_name);
        end if;
        -- always close the context in case of an error
        apex_exec.close(l_context);
        raise;
end execution;

end;
/


