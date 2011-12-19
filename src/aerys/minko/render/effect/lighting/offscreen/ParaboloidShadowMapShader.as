package aerys.minko.render.effect.lighting.offscreen
{
	import aerys.minko.render.effect.animation.AnimationStyle;
	import aerys.minko.render.shader.ActionScriptShader;
	import aerys.minko.render.shader.SValue;
	import aerys.minko.render.shader.parts.animation.AnimationShaderPart;
	import aerys.minko.render.shader.parts.math.projection.IProjectionShaderPart;
	import aerys.minko.render.shader.parts.math.projection.ParaboloidProjectionShaderPart;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.type.animation.AnimationMethod;
	
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class ParaboloidShadowMapShader extends ActionScriptShader
	{
		private static const PROJECTION_RECTANGLE	: Rectangle				= new Rectangle(-1, 1, 2, -2);
		
		private var _animationPart	: AnimationShaderPart	= null;
		
		private var _lightId		: uint					= 0;
		private var _projector		: IProjectionShaderPart	= null;
		
		private var _lightSpacePosition	: SValue;
		
		public function ParaboloidShadowMapShader(lightId	: uint,
										  front		: Boolean)
		{
			_lightId	= lightId;	
			_projector	= new ParaboloidProjectionShaderPart(this, front);
			
			_animationPart = new AnimationShaderPart(this);
		}
		
		override protected function getOutputPosition() : SValue
		{
			var animationMethod		: uint	 = uint(getStyleConstant(AnimationStyle.METHOD, AnimationMethod.DISABLED));
			var maxInfluences		: uint	 = uint(getStyleConstant(AnimationStyle.MAX_INFLUENCES, 0));
			var numBones			: uint	 = uint(getStyleConstant(AnimationStyle.NUM_BONES, 0));
			var vertexPosition		: SValue = _animationPart.getVertexPosition(animationMethod, maxInfluences, numBones);
			
			var localToLight		: SValue = getWorldParameter(16, LightData, LightData.LOCAL_TO_LIGHT, _lightId);
			var lightSpacePosition	: SValue = multiply4x4(vertexPosition, localToLight);
			var clipspacePosition	: SValue = _projector.projectVector(lightSpacePosition, PROJECTION_RECTANGLE, 0, 50);
			
			_lightSpacePosition = interpolate(lightSpacePosition);
			
			return float4(clipspacePosition, 1);
		}
		
		override protected function getOutputColor() : SValue
		{
			var clipspacePosition	: SValue = _projector.projectVector(_lightSpacePosition, PROJECTION_RECTANGLE, 0, 50);
			
			return float4(clipspacePosition.zzz, 1);
		}
		
		override public function getDataHash(styleData		: StyleData, 
											 transformData	: TransformData, 
											 worldData		: Dictionary) : String
		{
			var hash : String = 'frustumShadowMapDepthShader';
			hash += _animationPart.getDataHash(styleData, transformData, worldData)
			hash += _lightId;
			
			return hash;
		}
		
	}
}
