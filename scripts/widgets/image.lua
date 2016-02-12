local Widget = require "widgets/widget"

Image = Class(Widget, function(self, atlas, tex, default_tex)
    Widget._ctor(self, "Image")
    
    self.inst.entity:AddImageWidget()
    
    assert( ( atlas == nil and tex == nil ) or ( atlas ~= nil and tex ~= nil ) )

    self.tint = {1,1,1,1}

    if atlas and tex then
		self:SetTexture(atlas, tex, default_tex)
    end
end)

function Image:__tostring()
	return string.format("%s - %s:%s", self.name, self.atlas or "", self.texture or "")
end

function Image:SetAlphaRange(min, max)
	self.inst.ImageWidget:SetAlphaRange(min, max)
end

-- NOTE: the default_tex parameter is handled, but using 
-- it will produce a bunch of warnings in the log.
function Image:SetTexture(atlas, tex, default_tex)
    assert( atlas ~= nil )
    assert( tex ~= nil )

	self.atlas = type(atlas) == "string" and resolvefilepath(atlas) or atlas
	self.texture = tex
	--print(atlas, tex)
    self.inst.ImageWidget:SetTexture(self.atlas, self.texture, default_tex)

	-- changing the texture may have changed our metrics
	self.inst.UITransform:UpdateTransform()
end

function Image:SetMouseOverTexture(atlas, tex)
	self.atlas = type(atlas) == "string" and resolvefilepath(atlas) or atlas
	self.mouseovertex = tex
end

function Image:SetDisabledTexture(atlas, tex)
	self.atlas = type(atlas) == "string" and resolvefilepath(atlas) or atlas
	self.disabledtex = tex
end

function Image:SetSize(w,h)
    if type(w) == "number" then
        self.inst.ImageWidget:SetSize(w,h)
    else
        self.inst.ImageWidget:SetSize(w[1],w[2])
    end
end

function Image:GetSize()
    local w, h = self.inst.ImageWidget:GetSize()
    return w, h
end

function Image:ScaleToSize(w, h)
	local w0, h0 = self.inst.ImageWidget:GetSize()
	local scalex = w / w0
	local scaley = h / h0
	self:SetScale(scalex, scaley, 1)
end

function Image:SetTint(r,g,b,a)
    self.inst.ImageWidget:SetTint(r,g,b,a)
    self.tint = {r, g, b, a}
end

function Image:SetFadeAlpha(a, skipChildren)
	if not self.can_fade_alpha then return end
	
    self.inst.ImageWidget:SetTint(self.tint[1], self.tint[2], self.tint[3], self.tint[4] * a)
    Widget.SetFadeAlpha( self, a, skipChildren )
end

function Image:SetVRegPoint(anchor)
    self.inst.ImageWidget:SetVAnchor(anchor)
end

function Image:SetHRegPoint(anchor)
    self.inst.ImageWidget:SetHAnchor(anchor)
end

function Image:OnMouseOver()
	--print("Image:OnMouseOver", self)
	if self.enabled and self.mouseovertex then
		self.inst.ImageWidget:SetTexture(self.atlas, self.mouseovertex)
	end
	Widget.OnMouseOver( self )
end

function Image:OnMouseOut()
	--print("Image:OnMouseOut", self)
	if self.enabled and self.mouseovertex then
		self.inst.ImageWidget:SetTexture(self.atlas, self.texture)
	end
	Widget.OnMouseOut( self )
end

function Image:OnEnable()
    if self.mouse_over_self then
		self:OnMouseOver()
	else
		self.inst.ImageWidget:SetTexture(self.atlas, self.texture)
	end
end

function Image:OnDisable()
	self.inst.ImageWidget:SetTexture(self.atlas, self.disabledtex)
end

function Image:SetEffect(filename)
	self.inst.ImageWidget:SetEffect(filename)
end

function Image:SetEffectParams(param1, param2, param3, param4)
	self.inst.ImageWidget:SetEffectParams(param1, param2, param3, param4)
end

function Image:EnableEffectParams(enabled)
	self.inst.ImageWidget:EnableEffectParams(enabled)
end

function Image:SetUVScale(xScale, yScale)
	self.inst.ImageWidget:SetUVScale(xScale, yScale)
end
	
function Image:SetBlendMode(mode)
	self.inst.ImageWidget:SetBlendMode(mode)
end

return Image
