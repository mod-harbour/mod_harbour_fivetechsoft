// {% hb_SetEnv( "HB_USER_PRGFLAGS", "-B" ) %}

#xcommand TEXT INTO <v> => #pragma __cstream|<v>:=%s
#xcommand TEXT INTO <v> ADDITIVE => #pragma __cstream|<v>+=%s

static cContent, cAction, nId, cUserName

//----------------------------------------------------------------------------//

function Main()

   AltD()
   AltD( 1 )

   CheckDataBase()

   Controller( AP_Args() )

   AddLog()

return nil

//----------------------------------------------------------------------------//

function Controller( cRequest )

   local aRequest

   if ":" $ cRequest
      aRequest = hb_aTokens( cRequest, ":" )
      cRequest = aRequest[ 1 ]
      cAction  = aRequest[ 2 ]
      nId      = Val( aRequest[ 3 ] )
   endif    

   cContent = If( Empty( cRequest ), "home",;
       If( cRequest $ "home,logs,menus,routes,database,users,settings,tasks,controllers",;
           cRequest, "home" ) )

   do case   
      case AP_Method() == "GET"
         AP_RPuts( View( "default" ) )

      case AP_Method() == "POST"
         do case
            case cAction == "save"
                 Save()

            case cRequest == "login"
                 Login() 
         endcase 
   endcase   

return nil

//----------------------------------------------------------------------------//

function Router()

   local cRoute := "home"

   if GetContent() != "home"
      if GetAction() == "edit"
         cRoute = "edit"
      else   
         cRoute = "browse"
      endif
   endif      

return View( cRoute )      

//----------------------------------------------------------------------------//

function CheckDataBase()

   if ! File( hb_GetEnv( "PRGPATH" ) + "/data/logs.dbf" )
      DbCreate( hb_GetEnv( "PRGPATH" ) + "/data/logs.dbf",;
                { { "DATE",    "D", 8, 0 },;
                  { "TIME",    "C", 8, 0 },;
                  { "USERIP",  "C", 20, 0 },;
                  { "METHOD",  "C", 10, 0 },;
                  { "CONTENT", "C", 15, 0 },;
                  { "ACTION",  "C", 10, 0 },;
                  { "ID",      "N", 8, 0 } } )
   endif

   if ! File( hb_GetEnv( "PRGPATH" ) + "/data/users.dbf" )
      DbCreate( hb_GetEnv( "PRGPATH" ) + "/data/users.dbf",;
                { { "DATE",    "D",  8, 0 },;
                  { "FIRST",   "C", 20, 0 },;
                  { "LAST",    "C", 20, 0 },;
                  { "ACTIVE",  "L",  1, 0 },;
                  { "EMAIL",   "C", 20, 0 },;
                  { "PHONE",   "C", 20, 0 },;
                  { "PASSMD5", "C", 20, 0 },;
                  { "NOTES",   "M", 10, 0 } } )
   endif

   if ! File( hb_GetEnv( "PRGPATH" ) + "/data/tasks.dbf" )
      DbCreate( hb_GetEnv( "PRGPATH" ) + "/data/tasks.dbf",;
                { { "NAME",       "C", 20, 0 },;
                  { "DESCRIPTIO", "C", 40, 0 },;
                  { "CODE",       "M", 10, 0 } } )
   endif
   
return nil   

//----------------------------------------------------------------------------//

function AddLog()

   USE ( hb_GetEnv( "PRGPATH" ) + "/data/logs" ) SHARED NEW

   APPEND BLANK

   if RLock()
      field->date    := Date()
      field->time    := Time()
      field->userip  := AP_UserIP()
      field->method  := AP_Method()
      field->content := If( ! Empty( GetContent() ), GetContent(), "" )
      field->action  := If( ! Empty( GetAction() ), GetAction(), "" )
      field->id      := If( ! Empty( GetId() ), GetId(), 0 )
      DbUnLock()
   endif

   USE
   
return nil   

//----------------------------------------------------------------------------//

function Home()

   local cHtml 

   TEXT INTO cHtml
   <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
   <h2>mod_harbour Genesis visitors</h2>
   <div id="chart_div"></div>
   <script>
   google.charts.load('current', {packages: ['corechart', 'line']});
   google.charts.setOnLoadCallback(drawBackgroundColor);
   
   function drawBackgroundColor() {
         var data = new google.visualization.DataTable();
         data.addColumn('number', 'X');
         data.addColumn('number', 'Visitors');
   
         data.addRows([
           [0, 0],   [1, 10],  [2, 23],  [3, 17],  [4, 18],  [5, 9],
           [6, 11],  [7, 27],  [8, 33],  [9, 40],  [10, 32], [11, 35],
           [12, 30], [13, 40], [14, 42], [15, 47], [16, 44], [17, 48],
           [18, 52], [19, 54], [20, 42], [21, 55], [22, 56], [23, 57],
           [24, 60], [25, 50], [26, 52], [27, 51], [28, 49], [29, 53],
           [30, 55], [31, 60], [32, 61], [33, 59], [34, 62], [35, 65],
           [36, 62], [37, 58], [38, 55], [39, 61], [40, 64], [41, 65],
           [42, 63], [43, 66], [44, 67], [45, 69], [46, 69], [47, 70],
           [48, 72], [49, 68], [50, 66], [51, 65], [52, 67], [53, 70],
           [54, 71], [55, 72], [56, 73], [57, 75], [58, 70], [59, 68],
           [60, 64], [61, 60], [62, 65], [63, 67], [64, 68], [65, 69],
           [66, 70], [67, 72], [68, 75], [69, 80]
         ]);
   
         var options = {
           hAxis: {
             title: 'Time'
           },
           vAxis: {
             title: 'Popularity'
           },
           backgroundColor: '#f1f8e9'
         };
   
         var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
         chart.draw(data, options);
       }   
       </script>
   ENDTEXT

return cHtml

//----------------------------------------------------------------------------//

function Login()

   local hPairs := AP_PostPairs()
    
   do case
      case hb_HHasKey( hPairs, "forgot" )
         AP_RPuts( View( "default" ) )
         if ! Empty( hPairs[ "username" ] ) 
            AP_RPuts( "<script>MsgInfo( 'An email has been sent to you to reset your password' )</script>" )
         else   
            AP_RPuts( "<script>MsgInfo( 'Please write your email or phone number' )</script>" )
         endif 
         
      case hb_HHasKey( hPairs, "continue" )     
           if Identify( hPairs[ "username" ], hPairs[ "password" ] )
              cContent = "welcome"
              AP_RPuts( View( "default" ) )
           else
              AP_RPuts( View( "default" ) )
              AP_RPuts( "<script>MsgInfo( 'wrong username or password', 'Please try it again' )</script>" )
           endif 
           
      case hb_HHasKey( hPairs, "ok" )
           AddUser( hPairs )
           AP_RPuts( View( "default" ) )
           AP_RPuts( "<script>MsgInfo( 'Please identify and press continue' )</script>" )
   endcase 

return nil

//----------------------------------------------------------------------------//

function AddUser( hPairs )

   USE ( hb_GetEnv( "PRGPATH" ) + "/data/users" ) SHARED
   
   APPEND BLANK
   if RLock()
      field->first    := hb_HGet( hPairs, "first" )
      field->last     := hb_HGet( hPairs, "last" )
      field->email    := hb_UrlDecode( hb_HGet( hPairs, "email" ) )
      field->phone    := hb_HGet( hPairs, "phone" )
      field->password := hb_Md5( hb_HGet( hPairs, "password" ) )
      DbUnLock()
   endif   
   USE
   
return nil   

//----------------------------------------------------------------------------//

function Identify( _cUserName, _cPassword )

   local lFound

   USE ( hb_GetEnv( "PRGPATH" ) + "/data/users" ) SHARED

   LOCATE FOR ( field->email = hb_UrlDecode( _cUserName ) .or. field->phone = _cUserName ) .and. ;
                field->password = hb_Md5( _cPassword )
   
   lFound = Found()
   
   if lFound
      cUserName = field->first
   endif   

   USE

return lFound

//----------------------------------------------------------------------------//

function GetContent()

return cContent

//----------------------------------------------------------------------------//

function GetAction()

return cAction   

//----------------------------------------------------------------------------//

function GetId()

return nId   

//----------------------------------------------------------------------------//

function UserName()

return cUserName

//----------------------------------------------------------------------------//

function ItemStatus( cItem )

return If( cContent == cItem, "class='active'", "" ) 

//----------------------------------------------------------------------------//

function GetColor1() ; return "mediumblue"
function GetColor2() ; return "darkblue"
function GetColor3() ; return "rgb(34, 45, 50)"

//----------------------------------------------------------------------------//

function View( cView )

   local cViewName := hb_GetEnv( "PRGPATH" ) + "/views/" + cView + ".view" 
   local lFound := File( cViewName )
   local cData

   if lFound
      cData = MemoRead( cViewName )
    
      while ReplaceBlocks( @cData, "{{", "}}" )
      end
   else
      cData = "<h2>" + cViewName + " not found!</h2>" 
   endif    

return cData

//----------------------------------------------------------------------------//

function BuildBrowse( cTableName )

   local cHtml := "", n

   USE ( hb_GetEnv( "PRGPATH" ) + "/data/" + cTableName ) SHARED NEW

   if ! Empty( GetAction() ) .and. GetAction() == "add"
      APPEND BLANK
      GO TOP
   endif   

   if ! Empty( GetAction() ) .and. GetAction() == "del"
      USE
      USE ( hb_GetEnv( "PRGPATH" ) + "/data/" + cTableName ) NEW
      DbGoTo( GetId() )
      DELETE 
      PACK
      USE
      USE ( hb_GetEnv( "PRGPATH" ) + "/data/" + cTableName ) SHARED NEW
      GO TOP
   endif

   cHtml += '<table id="browse" class="table table-striped table-hover;">' + CRLF
   cHtml += '<thead>' + CRLF
   cHtml += '<tr>' + CRLF
   cHtml += '<th scope="col">#</th>' + CRLF

   for n = 1 to FCount() 
      cHtml += '<th scope="col">' + FieldName( n ) + '</th>' + CRLF
   next

   cHtml += '<th scope="col">ACTIONS</th>' + CRLF

   cHtml += '</tr>' + CRLF
   cHtml += '</thead>' + CRLF
   cHtml += '<tbody>' + CRLF

   while ! Eof()
      cHtml += "<tr>" + CRLF
      cHtml += '<th scope="row">' + AllTrim( Str( RecNo() ) ) + "</th>" + CRLF
      
      for n = 1 to FCount()
         do case
            case FieldType( n ) == "M"
               cHtml += '<td>' + SubStr( FieldGet( n ), 1, 20 ) + CRLF
               cHtml += '<button onclick="MsgInfo(' + "'" + ;
                        StrTran( FieldGet( n ), Chr( 13 ) + Chr( 10 ), "<br>" ) + "', '" + ;
                        FieldName( n ) + "');" + '"' + ;
                        ' type="button" class="btn btn-primary"' + CRLF 
               cHtml += '   style="border-color:gray;color:gray;background-color:#f9f9f9;">' + CRLF
               cHtml += '   <span class="glyphicon glyphicon-' + ;
                        If( FieldName( n ) == "CODE", "flash", "eye-open" ) + ;
                        '" style="color:gray;padding-right:10px;">' + CRLF
               cHtml += '   </span>' + If( FieldName( n ) == "CODE", "Exec", "View" ) + ;
                        '</button>' +  "</td>" + CRLF            
         
            case FieldType( n ) == "L"
               cHtml += '<td><input type="checkbox" onclick="return false;"' + ;
                        If( FieldGet( n ), "checked", "" ) + "></td>" + CRLF

            otherwise
               cHtml += '<td>' + ValToChar( FieldGet( n ) ) + "</td>" + CRLF   
         endcase   
      next

      cHtml += '<td>' + CRLF
      cHtml += '<button onclick="Edit(' + AllTrim( Str( RecNo() ) ) + ');"' + ;
               ' type="button" class="btn btn-primary"' + CRLF 
      cHtml += '   style="border-color:gray;color:gray;background-color:#f9f9f9;">' + CRLF
      cHtml += '   <span class="glyphicon glyphicon-edit" style="color:gray;padding-right:10px;">' + CRLF
      cHtml += '   </span>Edit</button>' + CRLF
      cHtml += '<button onclick="Delete(' + AllTrim( Str( RecNo() ) ) + ');"' + ;
               ' type="button" class="btn btn-primary"' + CRLF 
      cHtml += '   style="border-color:gray;color:gray;background-color:#f9f9f9;">' + CRLF
      cHtml += '   <span class="glyphicon glyphicon-trash" style="color:gray;padding-right:10px;">' + CRLF
      cHtml += '   </span>Delete</button>' + CRLF
      cHtml += '</td>' + CRLF

      SKIP
   end 

   cHtml += '</tbody>' + CRLF
   cHtml += '</table>' + CRLF

   USE

return cHtml   

//----------------------------------------------------------------------------//

function BuildEdit( cTableName )

   local cHtml := "", n

   USE ( hb_GetEnv( "PRGPATH" ) + "/data/" + cTableName ) SHARED NEW

   DbGoTo( GetId() )

   cHtml += '<form action="index.prg?' + GetContent() + ":save:" + AllTrim( Str( nId ) ) + '" ' + ;
            'method="post">' + CRLF
   cHtml += '<table id="browse" class="table table-striped table-hover;">' + CRLF
   cHtml += '<thead>' + CRLF
   cHtml += '</thead>' + CRLF
 
   for n = 1 to FCount()
      cHtml += '<tr>'
      cHtml += '   <td class="text-right">' + FieldName( n ) + "</td>"
      cHtml += '   <td class="center">'
      do case
         case FieldType( n ) == "M"
              cHtml += '<textarea class="form-control" rows="5" name="' + ;
              FieldName( n ) + '">' + FieldGet( n ) + '</textarea>' + CRLF

         case FieldType( n ) == "L"     
              cHtml += '<input type="checkbox" name="' + FieldName( n ) + ;
              '" class="form-control" style="border-radius:0px" ' + ;
              If( FieldGet( n ), "checked", "" ) + "></td>"

         otherwise   
              cHtml += '<input type="text" name="' + FieldName( n ) + ;
              '" class="form-control" style="border-radius:0px"' + ;
              " value='" + ValToChar( FieldGet( n ) ) + "'></td>"
      endcase            
      cHtml += '</tr>'
   next

   cHtml += '</table>' + CRLF

   USE

return cHtml

//----------------------------------------------------------------------------//

function Save()

   local hPost := AP_PostPairs(), n

   USE ( hb_GetEnv( "PRGPATH" ) + "/data/" + GetContent() ) SHARED NEW

   DbGoTo( nId )
   
   if RLock()
      for n = 1 to FCount()
         if hb_HHasKey( hPost, FieldName( n ) )
            do case
               case FieldType( n ) == "D"
                    FieldPut( n, CToD( hb_UrlDecode( hb_HGet( hPost, FieldName( n ) ) ) ) )

               case FieldType( n ) == "L"
                    FieldPut( n, "on" $ hb_UrlDecode( hb_HGet( hPost, FieldName( n ) ) ) )     
            
               otherwise   
                    FieldPut( n, hb_UrlDecode( hb_HGet( hPost, FieldName( n ) ) ) )
            endcase   
         else
            if FieldType( n ) == "L"
               FieldPut( n, .F. )
            endif      
         endif 
      next  
      DbUnLock()
   endif   

   USE

   AP_RPuts( View( "default" ) )

return nil

//----------------------------------------------------------------------------//

function hb_CapFirst( cText )

return Upper( Left( cText, 1 ) ) + SubStr( cText, 2 )   

//----------------------------------------------------------------------------//