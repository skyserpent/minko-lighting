package aerys.minko.render.shader.parts.lighting.type
{
	import aerys.minko.render.shader.ActionScriptShader;
	import aerys.minko.render.shader.ActionScriptShaderPart;
	import aerys.minko.render.shader.SValue;
	import aerys.minko.render.shader.compiler.ShaderConstSerializer;
	import aerys.minko.render.shader.parts.lighting.attenuation.MatrixShadowMapAttenuationShaderPart;
	import aerys.minko.render.shader.parts.lighting.contribution.InfiniteDiffuseShaderPart;
	import aerys.minko.render.shader.parts.lighting.contribution.InfiniteSpecularShaderPart;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.type.stream.format.VertexComponent;
	
	import flash.utils.Dictionary;
	
	public class DirectionalLightShaderPart extends ActionScriptShaderPart
	{
		private var _infiniteDiffusePart	: InfiniteDiffuseShaderPart				= null;
		private var _infiniteSpecularPart	: InfiniteSpecularShaderPart			= null;
		private var _matrixShadowMapPart	: MatrixShadowMapAttenuationShaderPart	= null;
		
		public function DirectionalLightShaderPart(main : ActionScriptShader)
		{
			super(main);
			
			_infiniteDiffusePart = new InfiniteDiffuseShaderPart(main);
			_infiniteSpecularPart = new InfiniteSpecularShaderPart(main);
			_matrixShadowMapPart = new MatrixShadowMapAttenuationShaderPart(main);
		}
		
		public function getDynamicLightContribution(lightId			: uint,
													lightData		: LightData,
													receiveShadows	: Boolean,
													position		: SValue = null,
													normal			: SValue = null) : SValue
		{
			position ||= getVertexAttribute(VertexComponent.XYZ);
			normal	 ||= getVertexAttribute(VertexComponent.NORMAL);
			
			var contribution	: SValue = float(0);
			var color			: SValue = getWorldParameter(3, LightData, LightData.COLOR, lightId);
			
			var diffuse : SValue = _infiniteDiffusePart.getDynamicTerm(lightId, lightData, position, normal);
			if (diffuse != null)
				contribution.incrementBy(diffuse);
			
			var specular : SValue = _infiniteSpecularPart.getDynamicTerm(lightId, lightData, position, normal);
			if (specular != null)
				contribution.incrementBy(specular);
			
			if (diffuse == null && specular == null)
				return null;
			
			if (receiveShadows)
				contribution.scaleBy(_matrixShadowMapPart.getDynamicFactor(lightId, position));
			
			return multiply(color, contribution);
		}
		
		public function getDynamicLightHash(lightData : LightData) : String
		{
			return _infiniteDiffusePart.getDynamicDataHash(lightData) 
				+ '|' + _infiniteSpecularPart.getDynamicDataHash(lightData);
		}
		
		public function getStaticLightContribution(lightId			: uint,
												   lightData		: LightData,
												   receiveShadows	: Boolean,
												   position			: SValue = null,
												   normal			: SValue = null) : SValue
		{
			position ||= getVertexAttribute(VertexComponent.XYZ);
			normal	 ||= getVertexAttribute(VertexComponent.NORMAL);
			
			var contribution	: SValue = float(0);
			var color			: SValue = float3(
				((lightData.color >>> 16) & 0xff) / 255, 
				((lightData.color >>> 8) & 0xff) / 255, 
				(lightData.color & 0xff) / 255
			); 
			
			var diffuse : SValue = _infiniteDiffusePart.getStaticTerm(lightId, lightData, position, normal);
			if (diffuse != null)
				contribution.incrementBy(diffuse);
			
			var specular : SValue = _infiniteSpecularPart.getStaticTerm(lightId, lightData, position, normal);
			if (specular != null)
				contribution.incrementBy(specular);
			
			if (diffuse == null && specular == null)
				return null;
			
			if (receiveShadows)
				contribution.scaleBy(_matrixShadowMapPart.getStaticFactor(lightId, lightData, position));
			
			return multiply(color, contribution);
		}
		
		public function getStaticLightHash(lightData : LightData) : String
		{
			return _infiniteDiffusePart.getStaticDataHash(lightData) 
				+ '|' + _infiniteSpecularPart.getStaticDataHash(lightData);
		}
		
		override public function getDataHash(styleData		: StyleData, 
											 transformData	: TransformData, 
											 worldData		: Dictionary) : String
		{
			throw new Error('Use get(Dynamic|Static)LightHash instead');
		}
		
	}
}
