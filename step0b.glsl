void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    // Normalized pixel coordinates (from 0 to 1)
	vec3 col ;
    vec2 centre;
    centre.x = iResolution.x/2.0;
    centre.y = iResolution.y/2.0;
    // Time varying pixel color
    if( mod(distance(centre, fragCoord), 20.0) >=10.0 )
    {
   	col = vec3(1.0,1.0,1.0);
    }
    else 
    {
     	col = vec3(0,0,0);
    }

    // Output to screen
    fragColor = vec4(col,1);

    //vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
}