prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_190200 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2019.10.04'
,p_release=>'19.2.0.00.18'
,p_default_workspace_id=>1620873114056663
,p_default_application_id=>102
,p_default_id_offset=>0
,p_default_owner=>'FOS_MASTER_WS'
);
end;
/

prompt APPLICATION 102 - FOS Dev - Plugin Master
--
-- Application Export:
--   Application:     102
--   Name:            FOS Dev - Plugin Master
--   Exported By:     FOS_MASTER_WS
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 61118001090994374
--     PLUGIN: 134108205512926532
--     PLUGIN: 1039471776506160903
--     PLUGIN: 547902228942303344
--     PLUGIN: 412155278231616931
--     PLUGIN: 1200087692794692554
--     PLUGIN: 461352325906078083
--     PLUGIN: 13235263798301758
--     PLUGIN: 37441962356114799
--     PLUGIN: 1846579882179407086
--     PLUGIN: 8354320589762683
--     PLUGIN: 50031193176975232
--     PLUGIN: 106296184223956059
--     PLUGIN: 35822631205839510
--     PLUGIN: 2674568769566617
--     PLUGIN: 14934236679644451
--     PLUGIN: 2600618193722136
--     PLUGIN: 2657630155025963
--     PLUGIN: 284978227819945411
--     PLUGIN: 56714461465893111
--     PLUGIN: 98648032013264649
--     PLUGIN: 455014954654760331
--     PLUGIN: 98504124924145200
--   Manifest End
--   Version:         19.2.0.00.18
--   Instance ID:     250144500186934
--

begin
  -- replace components
  wwv_flow_api.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/process_type/com_fos_download_files
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(56714461465893111)
,p_plugin_type=>'PROCESS TYPE'
,p_name=>'COM.FOS.DOWNLOAD_FILES'
,p_display_name=>'FOS - Download File(s)'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- =============================================================================',
'--',
'--  FOS = FOEX Open Source (fos.world), by FOEX GmbH, Austria (www.foex.at)',
'--',
'-- =============================================================================',
'',
'-- global contants',
'c_plugin_name constant varchar2(100) := ''FOS - Download File(s)'';',
'',
'-- helper function for converting clob to blob',
'function clob_to_blob',
'  ( p_clob    in clob',
'  )',
'return blob',
'as',
'    l_blob         blob;',
'    l_clob         clob   := empty_clob();',
'    l_dest_offset  number := 1;',
'    l_src_offset   number := 1;',
'    l_lang_context number := dbms_lob.default_lang_ctx;',
'    l_warning      number := dbms_lob.warn_inconvertible_char;',
'begin',
'',
'    if p_clob is null or dbms_lob.getlength(p_clob) = 0 ',
'    then',
'        dbms_lob.createtemporary',
'          ( lob_loc => l_clob',
'          , cache   => true',
'          );',
'    else',
'        l_clob := p_clob;',
'    end if;',
'',
'    dbms_lob.createtemporary',
'      ( lob_loc => l_blob',
'      , cache   => true',
'      );',
'',
'    dbms_lob.converttoblob',
'      ( dest_lob      => l_blob',
'      , src_clob      => l_clob',
'      , amount        => dbms_lob.lobmaxsize',
'      , dest_offset   => l_dest_offset',
'      , src_offset    => l_src_offset',
'      , blob_csid     => dbms_lob.default_csid',
'      , lang_context  => l_lang_context',
'      , warning       => l_warning',
'      );',
'',
'   return l_blob;',
'end clob_to_blob;',
'',
'-- helper function for raising errors',
'procedure raise_error',
'  ( p_message in varchar2',
'  , p0        in varchar2 default null',
'  , p1        in varchar2 default null',
'  , p2        in varchar2 default null',
'    )',
'as',
'begin',
'    raise_application_error(-20001, apex_string.format(c_plugin_name || '' - '' || p_message, p0, p1, p2));',
'end raise_error;',
'',
'-- main plug-in entry point',
'function execution',
'  ( p_process in apex_plugin.t_process',
'  , p_plugin  in apex_plugin.t_plugin ',
'  )',
'return apex_plugin.t_process_exec_result',
'as',
'    --attributes',
'    l_source_type     p_process.attribute_01%type := p_process.attribute_01;',
'    l_is_mode_plsql   boolean                     := (l_source_type = ''plsql'');',
'    ',
'    l_sql_query       p_process.attribute_02%type := p_process.attribute_02;',
'    l_plsql_code      p_process.attribute_03%type := p_process.attribute_03;',
'    l_archive_name    p_process.attribute_04%type := p_process.attribute_04;',
'    l_always_zip      boolean                     := (p_process.attribute_15 like ''%always-zip%'');',
'    l_disposition     p_process.attribute_15%type := case when p_process.attribute_15 like ''%inline-disposition%'' then ''inline'' else ''attachment'' end;   ',
'',
'    l_result          apex_plugin.t_process_exec_result;',
'',
'    -- used by the sql mode',
'    l_context         apex_exec.t_context;',
'    ',
'    l_pos_name        number;',
'    l_pos_mime        number;',
'    l_pos_blob        number;',
'    l_pos_clob        number;',
'    ',
'    l_blob_col_exists boolean := false;',
'    l_clob_col_exists boolean := false;',
'    ',
'    l_temp_file_name  varchar2(1000);',
'    l_temp_mime_type  varchar2(1000);',
'    l_temp_blob       blob;',
'    l_temp_clob       clob;',
'    ',
'    -- column names expected in the sql mode',
'    c_alias_file_name constant varchar2(20) := ''FILE_NAME'';',
'    c_alias_mime_type constant varchar2(20) := ''FILE_MIME_TYPE'';',
'    c_alias_blob      constant varchar2(20) := ''FILE_CONTENT_BLOB'';',
'    c_alias_clob      constant varchar2(20) := ''FILE_CONTENT_CLOB'';',
'',
'    -- used by the plsql mode',
'    c_collection_name constant varchar2(20) := ''FOS_DOWNLOAD_FILES'';',
'    ',
'    -- both modes',
'    l_final_file      blob;',
'    l_final_mime_type varchar2(1000);',
'    l_final_file_name varchar2(1000);',
'    ',
'    l_file_count      number;',
'    l_zipping         boolean;',
'begin',
'    -- debug',
'    if apex_application.g_debug ',
'    then',
'        apex_plugin_util.debug_process',
'          ( p_plugin  => p_plugin',
'          , p_process => p_process',
'          );',
'    end if;',
'    ',
'    -- creating a sql query based on the collection so we can reuse the logic for the sql mode',
'    if l_is_mode_plsql',
'    then',
'        apex_collection.create_or_truncate_collection(c_collection_name);',
'        apex_exec.execute_plsql(l_plsql_code);',
'        ',
'        l_sql_query := ''select c001    as file_name',
'                             , c002    as file_mime_type',
'                             , blob001 as file_content_blob',
'                             , clob001 as file_content_clob',
'                          from apex_collections',
'                         where collection_name = '''''' || c_collection_name || ''''''''',
'        ;',
'    end if;',
'',
'    l_context := apex_exec.open_query_context',
'                   ( p_location          => apex_exec.c_location_local_db',
'                   , p_sql_query         => l_sql_query',
'                   , p_total_row_count   => true',
'                   );',
'',
'    l_file_count := apex_exec.get_total_row_count(l_context);',
'',
'    if l_file_count = 0',
'    then',
'        raise_error(''At least 1 file must be provided'');',
'    end if;',
'',
'    -- we zip if there are more than 1 file or if always zip is turned on',
'    l_zipping := ((l_file_count > 1) or l_always_zip);',
'',
'    -- result set sanity checks',
'    begin',
'        l_pos_name := apex_exec.get_column_position',
'                        ( p_context     => l_context',
'                        , p_column_name => c_alias_file_name',
'                        , p_is_required => true',
'                        , p_data_type   => apex_exec.c_data_type_varchar2',
'                        );',
'    exception',
'        when others then',
'            raise_error(''A %s column must be defined'', c_alias_file_name);',
'    end;',
'',
'    begin',
'        l_pos_mime := apex_exec.get_column_position',
'                        ( p_context     => l_context',
'                        , p_column_name => c_alias_mime_type',
'                        , p_is_required => true',
'                        , p_data_type   => apex_exec.c_data_type_varchar2',
'                        );',
'    exception',
'        when others then',
'            raise_error(''A %s column must be defined'', c_alias_mime_type);',
'    end;',
'',
'    -- looping through all columns as opposed to using get_column_position',
'    -- as get_column_position writes an error to the logs if the column is not found',
'    -- even if the exception is handled',
'    l_blob_col_exists := false;',
'    l_clob_col_exists := false;',
'    ',
'    for idx in 1 .. apex_exec.get_column_count(l_context)',
'    loop',
'        if apex_exec.get_column(l_context, idx).name = c_alias_blob',
'        then',
'            l_pos_blob := idx;',
'            l_blob_col_exists := true;',
'        end if;',
'        ',
'        if apex_exec.get_column(l_context, idx).name = c_alias_clob',
'        then',
'            l_pos_clob := idx;',
'            l_clob_col_exists := true;',
'        end if;',
'    end loop;',
'',
'    -- raise an error if neither a blob nor a clob source was provided',
'    if not (l_blob_col_exists or l_clob_col_exists)',
'    then',
'        raise_error(''Either a %s or a %s column must be defined'', c_alias_blob, c_alias_clob);',
'    end if;',
'',
'    -- looping through all files',
'    while apex_exec.next_row(l_context)',
'    loop',
'',
'        if l_blob_col_exists',
'        then',
'            l_temp_blob := apex_exec.get_blob(l_context, l_pos_blob);',
'            if l_temp_blob is null',
'            then',
'                l_temp_blob := empty_blob();',
'            end if;',
'        end if;',
'',
'        if l_clob_col_exists',
'        then',
'            l_temp_clob := apex_exec.get_clob(l_context, l_pos_clob);',
'            if l_temp_clob is null',
'            then',
'                l_temp_clob := empty_clob();',
'            end if;',
'        end if;',
'        ',
'        l_temp_file_name := apex_exec.get_varchar2(l_context, l_pos_name);',
'        l_temp_mime_type := apex_exec.get_varchar2(l_context, l_pos_mime);',
'',
'        -- logic for choosing between the blob an clob',
'        if    (l_blob_col_exists and not l_clob_col_exists)',
'           or (l_blob_col_exists and l_clob_col_exists and dbms_lob.getlength(l_temp_blob) > 0) ',
'        then',
'            if apex_application.g_debug',
'            then',
'                apex_debug.message(''%s - BLOB - %s bytes'', l_temp_file_name, dbms_lob.getlength(l_temp_blob));',
'            end if;',
'            ',
'            if l_zipping',
'            then',
'                apex_zip.add_file',
'                  ( p_zipped_blob => l_final_file',
'                  , p_file_name   => l_temp_file_name',
'                  , p_content     => l_temp_blob',
'                  );',
'            else',
'                -- there''s only 1 file in the result set',
'                l_final_file_name := l_temp_file_name;',
'                l_final_mime_type := l_temp_mime_type;',
'                l_final_file      := l_temp_blob;',
'            end if;',
'        else',
'            if apex_application.g_debug',
'            then',
'                apex_debug.message(''%s - CLOB - %s bytes'', l_temp_file_name, dbms_lob.getlength(l_temp_clob));',
'            end if;',
'',
'            if l_zipping',
'            then',
'                apex_zip.add_file',
'                  ( p_zipped_blob => l_final_file',
'                  , p_file_name   => l_temp_file_name',
'                  , p_content     => clob_to_blob(l_temp_clob)',
'                  );',
'            else',
'                -- there''s only 1 file in the result set',
'                l_final_file_name := l_temp_file_name;',
'                l_final_mime_type := l_temp_mime_type;',
'                l_final_file      := clob_to_blob(l_temp_clob);',
'            end if;',
'        end if;',
'    end loop;',
'',
'    apex_exec.close(l_context);',
'    ',
'    if l_is_mode_plsql',
'    then',
'        apex_collection.delete_collection(c_collection_name);',
'    end if;',
'',
'    if l_zipping',
'    then',
'        apex_zip.finish(l_final_file);',
'        ',
'        if l_file_count = 1 then',
'            l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, l_temp_file_name || ''.zip''));',
'        else',
'            l_final_file_name := nvl(apex_application.g_x01, nvl(l_archive_name, ''files.zip''));',
'        end if;',
'        ',
'        l_final_mime_type := ''application/zip'';',
'        ',
'        if l_final_file_name not like ''%.zip'' ',
'        then',
'            l_final_file_name := l_final_file_name || ''.zip'';',
'        end if;',
'    end if;',
'',
'    sys.htp.init;',
'    sys.owa_util.mime_header(l_final_mime_type, false);',
'    sys.htp.p(''Content-Length: '' || dbms_lob.getlength(l_final_file));',
'    sys.htp.p(''Content-Disposition: ''||l_disposition||''; filename="'' || l_final_file_name || ''";'');',
'    sys.owa_util.http_header_close;',
'',
'    sys.wpg_docload.download_file(l_final_file);',
'    apex_application.stop_apex_engine;',
'',
'    return l_result;',
'exception',
'    -- this is the exception thrown by stop_apex_engine',
'    -- catching it here so it won''t be handled by the others handlers',
'    when apex_application.e_stop_apex_engine then',
'        raise;',
'    when others then',
'        -- delete the collection in case the error occurred between opening and closing it',
'        if apex_collection.collection_exists(c_collection_name)',
'        then',
'            apex_collection.delete_collection(c_collection_name);',
'        end if;',
'        -- always close the context in case of an error',
'        apex_exec.close(l_context);',
'        raise;',
'end execution;'))
,p_api_version=>2
,p_execution_function=>'execution'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The <strong>FOS - Download File(s)</strong> process plug-in enables the downloading of one or multiple database-stored BLOBs or CLOBs directly through the browser. You don''t have to worry about setting HTTP headers, converting CLOBs to BLOBs or zi'
||'pping the files. It''s all done for you. Just specify which files to download via a SQL query, or a more dynamic PL/SQL code block. Multiple files are zipped automatically, but a single file can optionally be zipped as well.</p>',
'',
'<h3>How to use this plug-in</h3>',
'<p>This plug-in should be instantiated as a <strong>Before Header</strong> process, with a serverside condition, usually in the form of REQUEST = VALUE. Whenever the page is requested with that specific request value, the download will start automati'
||'cally.</p>',
'<p>You would likely use this plug-in in one of two ways:',
'<ul>',
'<li>Start the download on click of a button. Simply set the button to submit the page, and specify the request value. Despite how it may seem, the download will simply start and the page will not actually reload.</li>',
'<li>Start the download when clicking on a link. Pre-build a link with the request value built in. When clicking on the link the download will start and the page will not proceed to reload.</li>',
'</ul>',
'</p>'))
,p_version_identifier=>'21.1.0'
,p_about_url=>'https://fos.world'
,p_plugin_comment=>'@fos-auto-return-to-page'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56729818611944642)
,p_plugin_id=>wwv_flow_api.id(56714461465893111)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Source Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'sql'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Choose how you wish to compile the list of files to download.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(56730103710945483)
,p_plugin_attribute_id=>wwv_flow_api.id(56729818611944642)
,p_display_sequence=>10
,p_display_value=>'SQL Query'
,p_return_value=>'sql'
,p_help_text=>'<p>The files should be based on a SQL query.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(56730557781946367)
,p_plugin_attribute_id=>wwv_flow_api.id(56729818611944642)
,p_display_sequence=>20
,p_display_value=>'PL/SQL Code'
,p_return_value=>'plsql'
,p_help_text=>'<p>The files should procedurally be added to an APEX collection in a PL/SQL code block.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56730937846958726)
,p_plugin_id=>wwv_flow_api.id(56714461465893111)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'SQL Query'
,p_attribute_type=>'SQL'
,p_is_required=>true
,p_sql_min_column_count=>3
,p_sql_max_column_count=>4
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56729818611944642)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'sql'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre>',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , blob_content as file_content_blob',
'  from some_table',
'</pre>',
'<pre>',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , clob_content as file_content_clob',
'  from some_table',
'</pre>',
'<pre>',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , blob_content as file_content_blob',
'     , null         as file_content_clob',
'  from some_table',
'',
' union all',
'',
'select file_name    as file_name',
'     , mime_type    as file_mime_type',
'     , null         as file_content_blob',
'     , clob_content as file_content_clob',
'  from some_table',
'</pre>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Provide the SQL query source for the files to be downloaded.</p>',
'<p>Columns <strong><code>file_name</code></strong> and <strong><code>file_mime_type</code></strong> are mandatory. Additionally, either <strong><code>file_content_blob</code></strong> or <strong><code>file_content_clob</code></strong> must be provide'
||'d. If both are provided, the first non-null one will be picked. This allows you to mix and match files from various sources.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(56731274214960583)
,p_plugin_id=>wwv_flow_api.id(56714461465893111)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'PL/SQL Code'
,p_attribute_type=>'PLSQL'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(56729818611944642)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'plsql'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre>',
'apex_collection.add_member',
'    ( p_collection_name => ''FOS_DOWNLOAD_FILES''',
'    , p_c001            => ''README.md''',
'    , p_c002            => ''text/plain''',
'    , p_clob001         => ''This zip contains *all* application files!''',
'    );',
'',
'for f in (',
'    select *',
'      from apex_application_static_files',
'     where application_id = :APP_ID',
') loop',
'    apex_collection.add_member',
'        ( p_collection_name => ''FOS_DOWNLOAD_FILES''',
'        , p_c001            => f.file_name',
'        , p_c002            => f.mime_type',
'        , p_blob001         => f.file_content',
'        );',
'end loop;',
'',
'-- pro tip: you can override the zip file name by assigning it to the apex_application.g_x01 global variable',
'apex_application.g_x01 := ''all_files.zip'';',
'</pre>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Provide the PL/SQL code block that compiles the files to be downloaded.</p>',
'<p>The files should be added one by one to the <strong><code>FOS_DOWNLOAD_FILES</code></strong> collection via the <code>apex_collection</code> API.</p>',
'<p>This special collection will be created and removed automatically.</p>',
'<p>Parameter <strong><code>p_c001</code></strong> is the file name, <strong><code>p_c002</code></strong> is the mime_type, <strong><code>p_blob001</code></strong> is the BLOB source and <strong><code>p_clob001</code></strong> is the CLOB source. <cod'
||'e>p_c001</code> and <code>p_c002</code> are both mandatory, and either <code>p_blob001</code> or <code>p_clob001</code> must be provided as well.</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(58107327041761022)
,p_plugin_id=>wwv_flow_api.id(56714461465893111)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Zip File Name'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
,p_examples=>'<code>db_files_export.zip</code>'
,p_help_text=>'<p>Enter the zip file name to be used in case multiple files are returned.</p>'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(58108494619889357)
,p_plugin_id=>wwv_flow_api.id(56714461465893111)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>150
,p_prompt=>'Extra Options'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Extra Options'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(58109565418905370)
,p_plugin_attribute_id=>wwv_flow_api.id(58108494619889357)
,p_display_sequence=>10
,p_display_value=>'Always Zip'
,p_return_value=>'always-zip'
,p_help_text=>'If the result set contains multiple files they will always be zipped. By default, if the result set contains only one file, it will not be zipped. Choose this option if a single file should be zipped as well.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(75925058460805167)
,p_plugin_attribute_id=>wwv_flow_api.id(58108494619889357)
,p_display_sequence=>20
,p_display_value=>'Inline Disposition'
,p_return_value=>'inline-disposition'
,p_help_text=>'<p>Check this option when you want to show the file/image rather than download (if the file is viewable e.g. a PDF or image</p>'
);
end;
/
prompt --application/end_environment
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done


