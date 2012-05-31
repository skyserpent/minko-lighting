package aerys.minko.render.shader.parts.lighting.attenuation
{
	import aerys.minko.ns.minko_lighting;
	import aerys.minko.render.effect.lighting.LightingProperties;
	import aerys.minko.render.shader.SFloat;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.render.shader.part.ShaderPart;
	import aerys.minko.type.enum.SamplerFiltering;
	import aerys.minko.type.enum.SamplerMipMapping;
	import aerys.minko.type.enum.SamplerWrapping;
	
	/**
	 * Fixme, bias should be:Total bias is m*SLOPESCALE + DEPTHBIAS
	 * Where m = max( | ∂z/∂x | , | ∂z/∂y | )
	 * ftp://download.nvidia.com/developer/presentations/2004/GPU_Jackpot/Shadow_Mapping.pdf
	 * 
	 * or maybe implement middle point shadow mapping to stop asking the user to manage shadow bias...
	 * 
	 * @author Romain Gilliotte
	 */
	public class MatrixShadowMapAttenuationShaderPart extends ShaderPart implements IAttenuationShaderPart
	{
		use namespace minko_lighting;
		
		private static const DEFAULT_BIAS : Number = 1 / 256;
		
		public function MatrixShadowMapAttenuationShaderPart(main : Shader)
		{
			super(main);
		}
		
		public function getAttenuation(lightId : uint, wPos : SFloat, wNrm : SFloat, iwPos : SFloat, iwNrm : SFloat) : SFloat
		{
			// retrieve shadow bias
			var shadowBias : SFloat;
			if (meshBindings.propertyExists(LightingProperties.SHADOWS_BIAS))
				shadowBias = meshBindings.getParameter(LightingProperties.SHADOWS_BIAS, 1);
			else if (sceneBindings.propertyExists(LightingProperties.SHADOWS_BIAS))
				shadowBias = sceneBindings.getParameter(LightingProperties.SHADOWS_BIAS, 1);
			else
				shadowBias = float(DEFAULT_BIAS);
			
			// retrieve depthmap and projection matrix
			var worldToUvName	: String = LightingProperties.getNameFor(lightId, 'worldToUV');
			var depthMapName	: String = LightingProperties.getNameFor(lightId, 'shadowMap');
			
			var worldToUV		: SFloat = sceneBindings.getParameter(worldToUvName, 16);
			var depthMap		: SFloat = 
				sceneBindings.getTextureParameter(depthMapName, SamplerFiltering.NEAREST, SamplerMipMapping.DISABLE, SamplerWrapping.CLAMP);
			
			// read expected depth from shadow map, and compute current depth
			var uv : SFloat;
			uv = multiply4x4(wPos, worldToUV);
			uv = interpolate(uv);
			var currentDepth		: SFloat = uv.z;
			uv = divide(uv, uv.w);
			
			var precomputedDepth	: SFloat = sampleTexture(depthMap, uv.xyyy).x;
			
			// shadow then current depth is less than shadowBias + precomputed depth
			return lessThan(currentDepth, add(shadowBias, precomputedDepth));
		}
	}
}
