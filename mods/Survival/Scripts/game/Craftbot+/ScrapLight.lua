scrapLight = class( nil )
scrapLight.maxChildCount = 0
scrapLight.maxParentCount = 1
scrapLight.connectionInput = sm.interactable.connectionType.logic
scrapLight.connectionOutput = sm.interactable.connectionType.none
scrapLight.poseWeightCount = 1

scrapLight.colorNormal = sm.color.new( 0xf6e46aff  )
scrapLight.colorHighlight = sm.color.new( 0xf7eb99ff  )

function scrapLight.client_onRefresh( self )
	self:client_onCreate()
end

function scrapLight.client_onCreate( self )
    if not self.lightEffect then self.lightEffect = sm.effect.createEffect( "HeadLight", self.interactable ) end
    self.lightEffect:setParameter("luminance", 0.7)
    self.lightEffect:setParameter("coneAngle", 32)
    self.lightEffect:setParameter("coneFade", 1)
    self.lightEffect:setParameter("range", 30)

    self.interactable:setPoseWeight(0, 1)
    self.lightEffect:start()
    self.wait = 6
    self.wasOff = false
end

function scrapLight.client_onFixedUpdate( self, dt )
    local parent = self.shape:getInteractable():getSingleParent()

    if not parent or parent.active then
        self.lightEffect:setParameter("color", self.shape.color)
        self.wait = self.wait-dt
        if self.wasOff then
            self.lightEffect:start()
            self.interactable:setPoseWeight(0, 1)
            self.wasOff = false
        end
        if self.wait <= 0 then
            if self.lightEffect:isPlaying() then
                self.wait = math.random(0.05,0.5)
                self.lightEffect:stop()
                self.interactable:setPoseWeight(0, 0)
            else
                self.wait = math.random(0.05,18)
                self.lightEffect:start()
                self.interactable:setPoseWeight(0, 1)
            end
        end
     else
        self.lightEffect:stop()
        self.interactable:setPoseWeight(0, 0)
        self.wasOff = true
     end
end

function scrapLight.client_onDestroy( self )
	if self.lightEffect then
		self.lightEffect:stop()
	end
end