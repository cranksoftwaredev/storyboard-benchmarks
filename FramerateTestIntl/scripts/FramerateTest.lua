-- Options to help with performance testing
	local g_update_banner = 1      --scroll the banner
	local g_update_boxes = 1       -- move boxes in and out
	local g_update_stars = 1       -- zoom starts in an out
	local g_show_stars = 1         -- hide the star completely
	local g_wrap_text = 1          -- wrap text in box
	local g_holder_text = 1        -- display text inside boxes
	local g_scale_box_images = 1   -- scale the image in the background of the box
	local g_run_time = 5           -- num seconds to run test for, 0 to not stop
--

local verticalConstraint = 100;
local horizontalConstraint = 100;
local scale = 1;
local panorama1X = 0;
local panorama2X = 0;

local sampleFPS = 0;
local sampleDuration = 500; --frames are incremented on each render, sampleDuration says how many milliseconds to average that data over before displaying
local lastSampledTime = 0;
local sampleFrames = 0;

local totalFPS = 0
local numSamples = 0
local prev = 0


function calculateFramerate()
	sampleFrames = sampleFrames + 1
	local diff = getTimer() - lastSampledTime;
	
	if diff >= sampleDuration then
		local rawFPS = sampleFrames/(diff/1000)
		sampleFPS = math.floor(rawFPS*100)/100 --format as XX.XX
		sampleFrames = 0;
		lastSampledTime = getTimer();
		
		totalFPS = totalFPS + sampleFPS
		numSamples = numSamples + 1
	end
end

function frametest_init(mapargs)
	local data = {}
	
---[[
	if g_wrap_text == 1 then
		data["box_layer.WordWrap"] = "wrap"
	else
		data["box_layer.WordWrap"] = "none"
	end
--]]
--[[
	if g_wrap_text == 1 then
		data["box_layer.WordWrap"] = 1
	else
		data["box_layer.WordWrap"] = 0
	end
--]]
	
	if g_scale_box_images == 1 then
		data["box_layer.BoxScale"] = 1
	else
		data["box_layer.BoxScale"] = 0
	end	
	
	if g_show_stars == 1 then
		data["Screen1.star_layer.grd_hidden"] = 0
	else
		data["Screen1.star_layer.grd_hidden"] = 1
	end
	
	if g_holder_text == 0 then
		data["box_layer.holder_text"] = ""
	end
	
	data["run_time"] = g_run_time * 1000
	
	gre.set_data(data)
	
	gre.send_event("timer_start")
	sendNextTick()
end

function getTimer()
	return gre.mstime(true)
end

-- This replaces the 20ms timer tick in the original test by driving
-- the next display tick as fast as possible.
function sendNextTick()
  gre.send_event("timer.tick")
end
	
function cb_got_timer(mapargs)
    local now = getTimer()
    if now > prev then
        calculateFramerate()
        tweenValues()
        executeBindings()
        prev = now
    end
	
	-- When we are event driven, we simulate the timer
	sendNextTick()
end
	
function tweenValues()
	--calulate see-saw values
	stretchTime = getTimer() % 2000;
	oneSecMilli = math.max(getTimer() % 1000, 1);
	oneSecDuration = 0
	
	if stretchTime < 1000 then
		oneSecDuration = 0+(oneSecMilli/1000)
	else
		oneSecDuration = 1-(oneSecMilli/1000)
	end
	
	verticalConstraint = 100+(oneSecDuration*200)
	horizontalConstraint = 100+(oneSecDuration*350)
	scale = 1+(oneSecDuration*4);
	
	--calculate panorama
	panTime = getTimer() % 4000;
	twoSecMilli = math.max(getTimer() % 2000, 1)
	twoSecPos = math.ceil((twoSecMilli/2000)*1000)
	
	if panTime < 2000 then
		panorama1X = 0-twoSecPos
		panorama2X = 1000-twoSecPos
	else
		panorama1X = 1000-twoSecPos
		panorama2X = 0-twoSecPos
	end
end

function px(val)
	return val+50;
end

function padMore(val)
	return (val+5)
end

function padLess(val)
	return (val-10)
end

function executeBindings()
	local data = {}
	--document.getElementById("panImage1").style.left = panorama1X+"px"
	--document.getElementById("panImage2").style.left = panorama2X+"px";
	data["fps"] = tostring(sampleFPS)
	
	if g_update_banner == 1 then
		data["banner_layer.banner1.grd_x"] = panorama1X
		data["banner_layer.banner2.grd_x"] = panorama2X
	end

	middleHorizW = 1000-(horizontalConstraint*2)
    middleVertH = 700-(verticalConstraint*2)
    
	if g_update_boxes == 1 then
		data["box_layer.holder1.grd_x"] = 0
		data["box_layer.holder1.grd_y"] = 0
		data["box_layer.holder1.grd_width"] = horizontalConstraint
		data["box_layer.holder1.grd_height"] = verticalConstraint
	
		data["box_layer.holder2.grd_x"] = padMore(horizontalConstraint)
		data["box_layer.holder2.grd_y"] = 0
		data["box_layer.holder2.grd_width"] = padLess(middleHorizW)
		data["box_layer.holder2.grd_height"] = verticalConstraint
	
		data["box_layer.holder3.grd_x"] = 1000-horizontalConstraint
		data["box_layer.holder3.grd_y"] = 0
		data["box_layer.holder3.grd_width"] = horizontalConstraint
		data["box_layer.holder3.grd_height"] = verticalConstraint
	
		data["box_layer.holder4.grd_x"] = 0
		data["box_layer.holder4.grd_y"] = padMore(verticalConstraint)
		data["box_layer.holder4.grd_width"] = horizontalConstraint
		data["box_layer.holder4.grd_height"] = padLess(middleVertH)
	
		data["box_layer.holder5.grd_x"] = padMore(horizontalConstraint)
		data["box_layer.holder5.grd_y"] = padMore(verticalConstraint)
		data["box_layer.holder5.grd_width"] = padLess(middleHorizW)
		data["box_layer.holder5.grd_height"] = padLess(middleVertH)
	
		data["box_layer.holder6.grd_x"] = 1000-horizontalConstraint
		data["box_layer.holder6.grd_y"] = padMore(verticalConstraint)
		data["box_layer.holder6.grd_width"] = horizontalConstraint
		data["box_layer.holder6.grd_height"] = padLess(middleVertH)
	
		data["box_layer.holder7.grd_x"] = 0
		data["box_layer.holder7.grd_y"] = 700-verticalConstraint
		data["box_layer.holder7.grd_width"] = horizontalConstraint
		data["box_layer.holder7.grd_height"] = verticalConstraint
	
		data["box_layer.holder8.grd_x"] = padMore(horizontalConstraint)
		data["box_layer.holder8.grd_y"] = 700-verticalConstraint
		data["box_layer.holder8.grd_width"] = padLess(middleHorizW)
		data["box_layer.holder8.grd_height"] = verticalConstraint
	
		data["box_layer.holder9.grd_x"] = 1000-horizontalConstraint
		data["box_layer.holder9.grd_y"] = 700-verticalConstraint
		data["box_layer.holder9.grd_width"] = horizontalConstraint
		data["box_layer.holder9.grd_height"] = verticalConstraint
	end

	if g_update_stars == 1 then
		-- set stars
		starsize = 100*scale
	
		data["star_layer.star1.grd_x"] = 500-(starsize/2)
		data["star_layer.star1.grd_y"] = 250-(starsize/2)
		data["star_layer.star1.grd_width"] = starsize
		data["star_layer.star1.grd_height"] = starsize
	
		data["star_layer.star2.grd_x"] = 500-(starsize/2)
		data["star_layer.star2.grd_y"] = 450-(starsize/2)
		data["star_layer.star2.grd_width"] = starsize
		data["star_layer.star2.grd_height"] = starsize
				
		starsize = 600-starsize;
	
		data["star_layer.star3.grd_x"] = 400-(starsize/2)
		data["star_layer.star3.grd_y"] = 350-(starsize/2)
		data["star_layer.star3.grd_width"] = starsize
		data["star_layer.star3.grd_height"] = starsize
	
		data["star_layer.star4.grd_x"] = 600-(starsize/2)
		data["star_layer.star4.grd_y"] = 350-(starsize/2)
		data["star_layer.star4.grd_width"] = starsize
		data["star_layer.star4.grd_height"] = starsize	
	end	
	
	gre.set_data(data)
end

--- Language Configuration Parameters
local latinText = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Morbi justo lacus, fringilla sed, malesuada sed, laoreet in, dolor. Donec ipsum enim, rhoncus vel, hendrerit ac, fermentum non, libero. Etiam id turpis. Quisque dignissim, nunc non porta mattis, nisl pede tincidunt purus, sit amet rhoncus turpis felis ut nunc. In velit turpis, vestibulum et, pulvinar in, dignissim a, tortor. Quisque imperdiet erat id est. Pellentesque sodales imperdiet leo. Suspendisse placerat. Nullam vel tellus. Nulla blandit, augue sed pretium mollis, leo libero consequat libero, ut euismod velit magna vel nisl. Donec posuere blandit pede. Nam et nibh ac eros malesuada gravida. Ut eget erat non arcu viverra eleifend. Morbi porta risus vel tortor. Ut massa. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Morbi justo lacus, fringilla sed, malesuada sed, laoreet in, dolor. Donec ipsum enim, rhoncus vel, hendrerit ac, fermentum non, libero. Etiam id turpis. Quisque dignissim, nunc non porta mattis, nisl pede tincidunt purus, sit amet rhoncus turpis felis ut nunc. In velit turpis, vestibulum et, pulvinar in, dignissim a, tortor. Quisque imperdiet erat id est. Pellentesque sodales imperdiet leo. Suspendisse placerat. Nullam vel tellus. Nulla blandit, augue sed pretium mollis, leo libero consequat libero, ut euismod velit magna vel nisl. Donec posuere blandit pede. Nam et nibh ac eros malesuada gravida. Ut eget erat non arcu viverra eleifend. Morbi porta risus vel tortor. Ut massa. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Morbi justo lacus, fringilla sed, malesuada sed, laoreet in, dolor. Donec ipsum enim, rhoncus vel, hendrerit ac, fermentum non, libero. Etiam id turpis. Quisque dignissim, nunc non porta mattis, nisl pede tincidunt purus, sit amet rhoncus turpis felis ut nunc. In velit turpis, vestibulum et, pulvinar in, dignissim a, tortor. Quisque imperdiet erat id est. Pellentesque sodales imperdiet leo. Suspendisse placerat. Nullam vel tellus. Nulla blandit, augue sed pretium mollis, leo libero consequat libero, ut euismod velit magna vel nisl. Donec posuere blandit pede. Nam et nibh ac eros malesuada gravida. Ut eget erat non arcu viverra eleifend. Morbi porta risus vel tortor. Ut massa."
local latinFont = "fonts/DejaVuSans.ttf"
local latinShaped = "script=Latin;lang=en"
local cyrillicText = "Вивендо десерунт цу нам, нец не десерунт малуиссет. Вис тимеам ментитум диспутандо те, еуисмод волутпат иус но. Но яуод ерат епицури еос. Ан дуо утинам импердиет. Ид усу толлит денияуе. Ипсум яуалисяуе симилияуе мел ут, про ид натум фугит платонем. Индоцтум витуперата вис еу, тота лорем промпта ид еос, еос цу промпта номинави диссентиунт. Сед яуас номинави цу. Оптион ерудити вивендум ат хас, вих хинц тритани цотидиеяуе но, ат вис вирис аудиам менандри. Не мелиус сцрипсерит вел. Ностер аццусата петентиум нец те. Вих чоро еуисмод не. Вих атяуи деленити ид. Сит те ерос цотидиеяуе адверсариум, но солута еффициантур вим, еум еу алиа сцрибентур. Хабео цоммодо не сед. Дуо проприае платонем еа, про татион темпор не, про ех пробо алиенум инцидеринт. Про вереар сенсерит индоцтум но. Сеа веро муциус ад, ут сеа цлита аппетере евертитур. Не пондерум евертитур вих, хас цонгуе оптион детерруиссет те. Интегре адиписцинг ад про, не усу ерат моллис виртуте, фацилиси перицула еурипидис еи еум. Яуо дицо денияуе дигниссим ан, долорес перицула яуаерендум еа яуо, те яуо атяуи елитр абхорреант. Ан иус солум юсто еурипидис, те вис сумо ностро лаборес. Вим дебет еуисмод еи. Оратио солута плацерат ин яуи. Перпетуа цотидиеяуе улламцорпер те нам, но еам еирмод цонсеяуунтур. Вим яуалисяуе инцидеринт интеллегебат ад. Афферт дицунт пхаедрум еу вим. Амет веро еум те. Ан апериам аперири про. Примис еррорибус ин ест, еи пауло дицам садипсцинг сит, еу елитр поссит цетерос нам. Иус ат мунди постеа, ин сит цлита вертерем. Долор феугаит ин вис, цетеро фацилиси яуо еу. Солет епицури волуптуа ех яуо. Примис инвенире цу вис. Иуварет партиендо хонестатис вих ан, но темпор апериам цопиосае вим. Цорпора деленити салутатус нец ад, яуи евертитур дефиниебас ех. Не нец витае дебитис. Алиа дицта ассуеверит хас. Ан дуо утинам импердиет. Ид усу толлит денияуе. Ипсум яуалисяуе симилияуе мел ут, про ид натум фугит платонем. Индоцтум витуперата вис еу, тота лорем промпта ид еос, еос цу промпта номинави диссентиунт. Сед яуас номинави цу. Оптион ерудити вивендум ат хас, вих хинц тритани цотидиеяуе но, ат вис вирис аудиам менандри. Не мелиус сцрипсерит вел. Ностер аццусата петентиум нец те. Вих чоро еуисмод не. Вих атяуи деленити ид. "
local cyrillicFont = "fonts/DejaVuSans.ttf"
local chineseText = "解的組人世政力作認的野停之單；河語統科坡心，成密有空片就不業就；印片是可？英方利際天向無布客呢之的十為你：遠始生化立古起代聽為：保四能只務藝放只。即會臺了導排起全星急的是小，看明始少只北孩題前理不小，股不盡後？者它全士所有資問不院使花兒著能信南神一為新府。我比亮的便樣。生路不操然清，手影專生今，意龍頭一異，果境有，沒場不修，到管史為轉來死十！方較。 政界發林出別動高來消從感西了檢乎評空英場邊；少眼破字題白義……讓上覺會主行提做樂傷，過超是同紙體同想信這衣中人一還遠治一運……策走帶區你、時經建：程養就巴二南對日媽品與臺雜兒來減？生品石不邊的散情功死行牛臺細性確登氣班接。口常之本，長安制作怕險國不是等卻怎親大外時兩可都庭報視如看了。愛產接電自臺明，點節家，強開小傳前難著讀人的：日長日天明們於候用路原便。 線看你天目，時下車保關候設分就隊，西小政會業如片頭片氣問天慢像充女學日式便演們界通不己，突童正響價語陽告思市樂，體視國戰能，之形作中物公苦主聲員說車是管、確將角下任庭人要；的而公要清己名可各排生輕己不離朋必處法不。遊都於叫……之展健力便家、物通起方議性、樂者蘭自千也得式且有朋經顯功。不都兩管資檢市目。不全言外正生：故的是政地是書包，入庭會星，造他興來無？歡紀老之中了新才法標員得風裡路人個呢常東位小害準情覺加著看定手人品始製光，就濟了的能建前此一的你，人報華後主定，曾己只為都了是大背容事到過……這一青總一法學我開論有由著，可以之就定出，五著然天我人速什直沒我年、是於黨以眼我服態立輕。去驚畫花清文壓都開小以英非告全過的賽大！ 式極問他景接；不統次、西外制印花角年業識他她雖明案藝，門童到色工件友線紀，式達父工此熱或集布？ 名第小裡當，你充己量不會也日：想何自創在，何還去臺。病有布中品大朋維親保，是臺星歷形一落。結險車縣答熱受題能綠錯，賽日氣，記好由再他學書害重程建管南最水理安……離此己腳相頭了書之精夜使：主前方因樂不智小新超靜格國年難開代，靜做錢可久打教！間兩名集路照麼會漸還象你一、由二靈想的到林面：那展營沒，是引生飛盡北身，斯不望過、算一面根些提參而我最研我次路……到什已供，中她收世加第爸子都史根得發生發間無手投專業；河外回個與前斷我？ 直力題體的下嗎活不增政時快告能是賽，作裝上哥死長是：教證當樓那設，國我心能兩相現面客可電大；賣而相學帶安。處新他們來庭向長。 商動同的的都養西評興、即起續了起慢不時不見，角熱吸學長為麼西對自的到，治發言心，水頭期！例源以候王們社成！因才合計溫館常農在願是車一快產自毒春這壓明不體話小話產臉道的入大至升沒區坡園甚家令西家就德果特寫外知？為懷的家，基是院：史生在臺作於，下清雜高對當都質特。分再而一到起說陸常下成決養我日天壓票絕？任的洲票對縣著？太法防；生不才專日太運於麼；雜漸以！南突不人快遠費原體地子這重才非風世所人自才會？解的組人世政力作認的野停之單；河語統科坡心，成密有空片就不業就；印片是可？英方利際天向無布客呢之的十為你：遠始生化立古起代聽為：保四能只務藝放只。即會臺了導排起全星急的是小，看明始少只北孩題前理不小，股不盡後？者它全士所有資問不院使花兒著能信南神一為新府。我比亮的便樣。生路不操然清，手影專生今？"
local chineseFont = "fonts/NotoSansCJKsc-Medium.otf"

-- Configures different text string content
local gTextConfigurationIndex = 1
local gTextConfigurations = { 
 { name="latin-unshaped", text=latinText, font=latinFont, script="" },
 { name="latin-shaped", text=latinText, font=latinFont, script=latinShaped },
 { name="cyrillic-unshaped", text=cyrillicText, font=cyrillicFont, script="" },
 { name="cyrillic-shaped", text=cyrillicText, font=cyrillicFont, script=latinShaped },
 { name="chinese-unshaped", text=chineseText, font=chineseFont, script="" },
 { name="chinese-shaped", text=chineseText, font=chineseFont, script=latinShaped },
}

function languageFlip(config)
  local data = {}
  data["box_layer.holder_text"] = config.text
  data["box_layer.fontName"] = config.font
  data["grd_text_shaper_attrs"] = config.script
  gre.set_data(data)
end

-- Allow the user to force a language flip from outside
function cb_set_holder_text(mapargs)
  local evData = mapargs.context_event_data
  local value = evData.value
  for i=1,#gTextConfigurations do
    local config = gTextConfigurations[i]
    if(config.name == value) then
      gTextConfigurationIndex = i
      languageFlip(config)
    end
  end
end

function reportPerformance()
  local FPS = totalFPS / numSamples
  
  local label = string.format("FramerateTestIntl-%s", gTextConfigurations[gTextConfigurationIndex].name)
  gre.log_perf_stat("FramerateTestIntl", label, FPS, "fps")

  -- Reset the values to re-report
  totalFPS = 0
  numSamples = 0
end

function cb_exit(mapargs)
  reportPerformance()
	
	gTextConfigurationIndex = gTextConfigurationIndex + 1
	if(gTextConfigurationIndex > #gTextConfigurations) then
    gre.send_event("gre.quit")
  else
    languageFlip(gTextConfigurations[gTextConfigurationIndex])
  end
end
