//----------------------------------------------------------------//

function Main()
   
   ? '<meta http-equiv="refresh" content="1"/>'
   
   ? Time(), '<hr>'
   
   ? 'cookie value: ', GetCookie( 'MyCookieName' )
    
return nil

//----------------------------------------------------------------//

function GetCookie( cCookieName )

   local hHeadersIn := AP_HeadersIn()
   
return If( hb_HHasKey( hHeadersIn, "Cookie" ), hb_hGet( hHeadersIn, "Cookie" ), "" )

//----------------------------------------------------------------//