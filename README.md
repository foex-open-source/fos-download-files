## FOS - Download File(s)

![](https://img.shields.io/badge/Plug--in_Type-Process-orange.svg) ![](https://img.shields.io/badge/APEX-19.2-success.svg) ![](https://img.shields.io/badge/APEX-20.1-success.svg) ![](https://img.shields.io/badge/APEX-20.2-success.svg)

Download of database-stored BLOBs and CLOBs using a "Before Header" process. Multiple files are zipped automatically.
<h4>Free Plug-in under MIT License</h4>
<p>
All FOS plug-ins are released under MIT License, which essentially means it is free for everyone to use, no matter if commercial or private use.
</p>
<h4>Overview</h4>
<p>The <strong>FOS - Download File(s)</strong> process plug-in enables the downloading of one or multiple database-stored BLOBs or CLOBs directly through the browser. You don't have to worry about setting HTTP headers, converting CLOBs to BLOBs or zipping the files. It's all done for you. Just specify which files to download via a SQL query, or a more dynamic PL/SQL code block. Multiple files are zipped automatically, but a single file can optionally be zipped as well.</p>

<h3>How to use this plug-in</h3>
<p>This plug-in should be instantiated as a <strong>Before Header</strong> process, with a serverside condition, usually in the form of REQUEST = VALUE. Whenever the page is requested with that specific request value, the download will start automatically.</p>
<p>You would likely use this plug-in in one of two ways:
<ul>
<li>Start the download on click of a button. Simply set the button to submit the page, and specify the request value. Despite how it may seem, the download will simply start and the page will not actually reload.</li>
<li>Start the download when clicking on a link. Pre-build a link with the request value built in. When clicking on the link the download will start and the page will not proceed to reload.</li>
</ul>
</p>

## License

MIT

