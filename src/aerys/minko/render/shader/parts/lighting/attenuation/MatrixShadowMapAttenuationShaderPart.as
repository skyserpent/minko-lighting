package aerys.minko.render.shader.parts.lighting.attenuation
{
	import aerys.minko.render.effect.Style;
	import aerys.minko.render.effect.lighting.LightingStyle;
	import aerys.minko.render.shader.ActionScriptShader;
	import aerys.minko.render.shader.ActionScriptShaderPart;
	import aerys.minko.render.shader.SValue;
	import aerys.minko.render.shader.node.leaf.Sampler;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.type.stream.format.VertexComponent;
	
	/**
	 * Fixme, bias should be:Total bias is m*SLOPESCALE + DEPTHBIAS
	 * Where m = max( | ∂z/∂x | , | ∂z/∂y | )
	 * ftp://download.nvidia.com/developer/presentations/2004/GPU_Jackpot/Shadow_Mapping.pdf
	 * 
	 * @author Romain Gilliotte <romain.gilliotte@aerys.in>
	 * 
	 */	
	public class MatrixShadowMapAttenuationShaderPart extends ActionScriptShaderPart implements IAttenuationShaderPart
	{
		public function MatrixShadowMapAttenuationShaderPart(main : ActionScriptShader)
		{
			super(main);
		}
		
		public function getDynamicFactor(lightId	: uint,
										 position	: SValue = null) : SValue
		{
			position ||= getVertexAttribute(VertexComponent.XYZ);
			
			var lightDepthSamplerId	: uint	 = Style.getStyleId('lighting matrixDepthMap' + lightId);
			var lightLocalToUV		: SValue = getWorldParameter(16, LightData, LightData.LOCAL_TO_UV, lightId)
			var shadowBias			: SValue = getStyleParameter(1, LightingStyle.SHADOWS_BIAS, 1 / 100);
			
			var uv : SValue;
			uv = multiply4x4(position, lightLocalToUV);
			uv = divide(uv, uv.w);
			uv = interpolate(uv);
			
			var currentDepth : SValue = uv.z;
			
			var precomputedDepth : SValue;
			precomputedDepth = sampleTexture(lightDepthSamplerId, uv, Sampler.FILTER_LINEAR, Sampler.MIPMAP_DISABLE, Sampler.WRAPPING_CLAMP);
			precomputedDepth = precomputedDepth.x;
//			precomputedDepth = unpack(precomputedDepth);
			
			return lessThan(currentDepth, add(shadowBias, precomputedDepth));
		}
		
		public function getStaticFactor(lightId		: uint,
										lightData	: LightData,
										position	: SValue = null) : SValue
		{
			return getDynamicFactor(lightId, position);
		}
		
	}
}
