void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = fragCoord/iResolution.xy;
	vec3 col ;
    // Time varying pixel color
    if( mod(fragCoord.x, 20.0) <=10.0 )
    {
   		col = vec3(1.0,1.0,1.0);
    }
    else 
    {
     	col = vec3(0,0,0);
    }

    // Output to screen
    fragColor = vec4(col,1);
}