package aerys.minko.render.effect.lighting
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.IEffectPass;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.renderer.state.Blending;
	import aerys.minko.render.renderer.state.CompareMode;
	import aerys.minko.render.renderer.state.RendererState;
	import aerys.minko.render.renderer.state.TriangleCulling;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.light.ClipspacePositionFromLight;
	import aerys.minko.render.shader.node.light.PackedDepthFromLight;
	import aerys.minko.scene.data.StyleStack;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.ViewportData;
	
	import flash.utils.Dictionary;
	
	public class LightDepthPass implements IEffectPass
	{
		protected var _shader				: Shader;		
		protected var _lightIndex			: uint;
		protected var _priority				: Number;
		protected var _renderTarget			: RenderTarget;
		
		public function LightDepthPass(lightIndex	: uint			= 0,
									   priority		: Number		= 0,
									   renderTarget	: RenderTarget	= null)
		{
			_lightIndex			= lightIndex;
			_priority			= priority;
			_renderTarget		= renderTarget;
			_shader				= createShader(lightIndex);
		}
		
		protected function createShader(lightIndex : uint) : Shader
		{
			var clipspacePosition	: INode	= new ClipspacePositionFromLight(_lightIndex);
			var pixelColor			: INode	= new PackedDepthFromLight(_lightIndex);
			
			return Shader.create(clipspacePosition, pixelColor);
		}
		
		public function fillRenderState(state			: RendererState,
										styleData		: StyleStack, 
										transformData	: TransformData,
										worldData		: Dictionary) : Boolean
		{
			if (!styleData.get(LightingStyle.CAST_SHADOWS, false))
				return false;
			
			state.blending			= Blending.NORMAL;
			state.depthTest			= CompareMode.LESS
			state.priority			= _priority;
			state.renderTarget		= _renderTarget || worldData[ViewportData].renderTarget;
			state.program			= _shader.resource;
			state.triangleCulling	= styleData.get(BasicStyle.TRIANGLE_CULLING, TriangleCulling.BACK) as uint;
			
			_shader.fillRenderState(state, styleData, transformData, worldData);
			
			return true;
		}
	}
}