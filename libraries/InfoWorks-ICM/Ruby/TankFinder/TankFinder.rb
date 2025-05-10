require_relative 'LinkWalker.rb'
require 'pp'

#Obtain the cross sectional area of a polygon
#param [IN] points: Array<Array<Float>> - Array of [x,y] points
#return [Float] - Area of the polygon
def areaForPolygon(points)
    area = 0
    points.each_with_index do |point, index|
        nextPoint = points[(index+1) % points.length]
        area += (nextPoint[0] - point[0]) * (nextPoint[1] + point[1])
    end
    return area.abs/2
end

#Obtain the cross sectional area of a pipe
#param [IN] net: WSOpenNetwork - Network to find shapes in
#param [IN] pipe: WSModelObject - Pipe to get the cross sectional area of
#return [Float] - Cross sectional area of the pipe
def getPipeCrossSectionalArea(net, pipe)
    shape = net.RowObject("hw_shape", pipe.shape.upcase)
    h = pipe.height
    w = pipe.width
    case shape.shape_type.upcase
    when "Builtin"
        case pipe.shape
        when "CIRC"
            return Math::PI * (w/2)**2
        when "RECT"
            return w * h
        when "EGG"
            return (Math::PI * (w/2)**2)/2 + (Math::PI * ((h-w)/2)**2)/2 + (h/2)**2
        when "EGG2"
            area_trap = h*(h+w)/8
            area_upper = Math::PI * (w/2)**2 /2
            area_lower = Math::PI * ((h-w)/4)**2 /2
            return area_trap + area_upper + area_lower
        when "ARCH"
            return w * (h-w/2) + Math::PI * (w/2)**2 /2
        when "ARCHSPRUNG"
            hs = pipe.springing_height
            return w * hs + Math::PI * (h-hs) * (w/2)
        when "CNET"
            return (Math::PI * (w/2)**2)/2 + (Math::PI * (h-w/2)**2)/2
        when "OVAL"
            area_upperAndLower = Math::PI * (w/2)**2
            area_sides = w * (h-w)
            return area_upperAndLower + area_sides
        when "UTOP"
            area_rect = w * h - w/2
            area_semi = Math::PI * (w/2)**2 /2
            return area_rect + area_semi
        #Channels
        when "OEGB"
            trap_height = 3/4 * h + w/8
            trap_area = trap_height * (w + (h-w/2)/2)/2
            semi_area = Math::PI * ((h-w/2)/4)**2 / 2
            return trap_area + semi_area
        when "OEGN"
            #TODO
            return nil
        when "OREC"
            return w * h
        when "OT1:1"
            return w * h * 2
        when "OT1:2"
            return w * h + 2 * w * h 
        when "OT1:4"
            return w * h + 4 * w * h 
        when "OT1:6"
            return w * h + 6 * w * h 
        when "OT2:1"
            return w * h + w * 2 * h 
        when "OT4:1"
            return w * h + w * 4 * h 
        when "OU"
            area_rect = w * h - w/2
            area_semi = Math::PI * (w/2)**2 /2
            return area_rect + area_semi
        else
            return nil
        end
    when "Symmetric"
        leftPoints = shape.geometry.enum_for(:each).map{|row| [row.height*h, row.left*w]}
        return areaForPolygon(leftPoints) * 2
    when "Asymmetric"
        leftPoints = shape.geometry.enum_for(:each).map{|row| [row.height*h, row.left*w]}
        rightPoints = shape.geometry.enum_for(:each).map{|row| [row.height*h, row.right*w]}
        polygon = leftPoints + rightPoints.reverse
        return areaForPolygon(polygon)
    else
        return nil
    end
end

def getOpeningArea(net, link)
    case link.table.name.downcase
    when "hw_conduit"
        return getPipeCrossSectionalArea(net, link)
    when "hw_orifice"
        case link.link_type.upcase
        when "ORIFIC"
            return Math::PI * (link.diameter / 2)**2 #Assume circle
        when "VLDORF"
            return Math::PI * (link.diameter / 2)**2 #Assumed
        end
    when "hw_weir"
        case link.link_type.upcase
        when "WEIR"
            # Assume rectangular opening above weir
            return (link.us_node.chmaber_roof - link.crest) * link.width
        when "VCWEIR"
            return nil #TODO:
        when "VWWEIR"
            return nil #TODO:
        when "COWEIR"
            return nil #TODO:
        when "VNWEIR"
            return nil #TODO:
        when "TRWEIR"
            return nil #TODO:
        when "BRWEIR"
            return nil #TODO:
        when "GTWEIR"
            return nil #TODO:
        end
    when "hw_flap"
        return Math::PI * (link.diameter / 2)**2 #Assume circle
    when "hw_pump"
        return 0
    when "hw_sluice"
        case link.link_type.upcase
        when "SLUICE"
            return link.opening * link.width
        when "VSGATE"
            return link.opening * link.width #Assumed
        when "RSGATE"
            return nil #TODO:
        when "VRGATE"
            return nil #TODO:
        end
    end
end


def findTanks()
    net = WSApplication.current_network
    tankCandidates = net.row_objects("hw_pipe").filter do |pipe|
        #Get pipe cross sectional area
        pipeArea = getPipeCrossSectionalArea(net, pipe)
        
        #Get sum of downstream cross sectional areas
        dsPipeArea = pipe.ds_node.navigate("ds_pipes").sum {|dsPipe| getPipeCrossSectionalArea(net, dsPipe)}

        #If the downstream cross sectional area is significantly less than the current pipe cross sectional area, 
        #then the current pipe is likely a tank-end (at least 40000 mm^2 decrease)
        #TODO: handle non native units
        next dsPipeArea < (pipeArea - 40000)
    end

    #With tank candidates trace upstream until cross sectional area is significantly lower (i.e. < 40k difference)
    tanks = tankCandidates.map do |pipe|
        #Get pipe cross sectional area
        pipeArea = getPipeCrossSectionalArea(net, pipe)
        
        tankWalkers = traceTil(pipe, "us") do |latestPipe, walker|
            #Get pipe cross sectional area
            latestPipeArea = getPipeCrossSectionalArea(net, latestPipe)
            
            #If the latest pipe cross sectional area is significantly less than the current pipe cross sectional area, 
            #then the current pipe is likely a tank-end (at least 40000 mm^2 decrease)
            next latestPipeArea < (pipeArea - 40000)
        end

        next {:walkers => tankWalkers, :endPipe => pipe}
    end.filter do |walkerSet|
        #Ensure length of tank < 1km
        walkerSet[:walkers].each {|walker| walker.meta.total_length = walker.links.reduce {|sum, link| sum + link.conduit_length} < 1000
        next !walkerSet[:walkers].all {|walker| walker.meta.total_length < 1000}
    end.map do |walkerSet|
        walkerSet[:tankLinks] = walkerSet[:walkers].map do |walker|
            walker.links
        end.flatten.uniq {|link| link.id}
        next walkerSet
    end
    return tanks
end

pp findTanks()