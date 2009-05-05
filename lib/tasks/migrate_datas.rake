
    
namespace :zz do


  
  desc "Recompute random images for categories" 
  task(:category_images => :environment) do
      Category.find(:all).each { |category|  
        puts "processing category=#{category.label}"
        products = category.products_all
        if products.size > 0
          product = products[rand(products.size)]
          puts "product=#{product}"
          category.image_file_url = "http://localhost:3000/products/#{product.id}.jpg"
          category.products_all_count = products.size
          category.save
        end
      }
  end
  
  desc "Reset datas" 
  task(:reset_datas => :environment) do

    puts "recompute Category hierarchy"
    Category.renumber_all
      
    puts "recompute Path of products"
    Product.find(:all).each { |product| 
      product.category_path = product.category.path
      product.save }
     
    # recompute counters
    puts "recompute Users counters"
    User.find(:all).each { |o|    
      puts "authored_products_count=#{o.authored_products.count} for user #{o.screen_name}" 
      User.update_all({ :authored_tips_count => o.authored_tips.count,
                        :authored_opinions_count => o.authored_tips.count,
                        :authored_questions_count => o.authored_questions.count,
                        :authored_products_count => o.authored_products.count,
                        :authored_reviews_count => o.authored_reviews.count }, "id=#{o.id}") 
    }
    
    puts "recompute Question counters"
    Question.find(:all).each { |o| 

      puts "--------> weighted_sums (question_id=#{o.id})=#{o.weighted_sums.inspect}"
      Question.update_all({ :tips_count => o.tips.count,
                            :interest => nil,
                            :confidence => 0.0 }, 
                          "id=#{o.id}")
    }

    puts "recompute Tips counters"
    Tip.find(:all).each { |o| 
      puts "--------> weighted_sums (tip_id=#{o.id})=#{o.weighted_sums.inspect}"
      Tip.update_all({:opinions_count => o.opinions_count,
                      :interest => nil,
                      :confidence => 0.0}, 
                    "id=#{o.id}")
    }
    Opinion.find(:all).each { |opinion| opinion.update_counters }
    
    puts "recompute Products counters"
    Product.find(:all).each { |o| 
      Product.update_all({:tips_count => o.tips.count,
                          :reviews_count => o.reviews.count,
                          :weighted_sum_reviews => 0.0,
                          :weighted_sum_reviews_all => 0.0 }, "id=#{o.id}")
    }
    Review.find(:all).each { |review| review.update_counters }
   
    puts "recompute product similarities"
    ProductSimilarity.delete_all
    Product.find(:all).each { |product| product.compute_similarities(1.0, false) }
    
    puts "recompute Category counters"
    Category.find(:all).each { |o| 
      Category.update_all({:products_count => o.products.count}, "id=#{o.id}")
    }

    puts "recompute state of Tips"
    Tip.find(:all).each { |o| o.publish! }
    
    puts "recompute state of Questions"
    Question.find(:all).each { |o| o.publish! }
    
    puts "recompute state of products"
    Product.find(:all).each { |o|  o.reset! }

  end

  
  desc "Reset database with a basic model" 
  task(:reset_database => :environment) do

    # Remove all amazon users !
    User.delete_all("login like 'amazon_cust%'")
    
    # Categories
    Category.roots.each { |category| category.remove_node }
	
    #raise "top"
    category_all = Category.add_new_default_category("all")
    Category.add_new_default_category("Services", category_all)
    category_products = Category.add_new_default_category("Products", category_all)
    Category.add_new_default_category("Electronic products", category_products)
    category_telephones = Category.add_new_default_category("Telephones", category_products)
    category_televisions = Category.add_new_default_category("Televisions", category_products)
    
    # ------------------------------------------------------------------------------------
    # Features
    # ------------------------------------------------------------------------------------
    # Product Level
    
    feature_brand = category_telephones.add_new_default_feature("tag", nil, "brand", {:set_tags => [
      "Nokia", "Motorola", "BlackBerry", "Sony Ericsson", "Samsung", "LG Electronics",
      "Apple", "Sanyo", "Siemens", "Audiovox"]})
    feature_price = category_telephones.add_new_default_feature("numeric_interval", nil, "price", {:min => 1, :max => 5000, :format => "% .2f$"})
    feature_date = category_telephones.add_new_default_feature("date", nil, "released_on")
    feature_date_status = category_telephones.add_new_default_feature("tag", feature_date.id, "status", {:set_tags => ["announcement", "released"]})
        
    # Telephone level
    feature_tip = category_telephones.add_new_default_feature("header", nil, "tips")
    feature_tip_good_for = category_telephones.add_new_default_feature("tags", feature_tip.id, "good_for", {:set_tags => []})
    feature_tip_bad_for = category_telephones.add_new_default_feature("tags", feature_tip.id, "bad_for", {:set_tags => []})
    
    feature_general = category_telephones.add_new_default_feature("header", "general")
    feature_general_nickname = category_telephones.add_new_default_feature("text", feature_general.id, "nickname")
    feature_general_carriers = category_telephones.add_new_default_feature("tags", feature_general.id, "carriers", {:set_tags => [
      "Verizon", "AT&T", "T-Mobile", "Sprint Nextel", "Qwest", "AllTel", "U.S. Cellular", 
      "Cricket", "Virgin Mobile", "PowerNet Mobile"]})
    feature_general_weight = category_telephones.add_new_default_feature("numeric", feature_general.id, "weight", {:min => 1, :max => 300, :format => "% .2foz"})
    feature_general_size = category_telephones.add_new_default_feature("text", feature_general.id, "size")    

    # Hardware
    feature_hardware = category_telephones.add_new_default_feature("header", nil, "hardware")
    feature_hardware_screen = category_telephones.add_new_default_feature("header", feature_hardware.id, "screen")
    feature_hardware_screen_type = category_telephones.add_new_default_feature("tags", feature_hardware_screen.id, "type", {:set_tags => ["touch", "haptic feedback (screen that clicks)"]})
    feature_hardware_screen_resolution = category_telephones.add_new_default_feature("tag", feature_hardware_screen.id, "resolution", {:set_tags => ["160x80", "320x240"]})
    feature_hardware_screen_nb_colors = category_telephones.add_new_default_feature("numeric", feature_hardware_screen.id, "nb_colors", {:min => 1, :max => 10, :format => "% .1f Mpx"})
    feature_hardware_virtual_keyboard = category_telephones.add_new_default_feature("binary", feature_hardware.id, "virtual_keyboard")
    feature_hardware_virtual_keyboard_mode = category_telephones.add_new_default_feature("tags", feature_hardware_virtual_keyboard.id, "mode", {:set_tags => ["landscape", "portraits"]})
    
    feature_hardware_ = category_telephones.add_new_default_feature("tags", feature_hardware.id, "form_factor", {:set_tags => ["candy bar", "touch screen", "clamshell", "swivel", "slider"]})
    feature_hardware_ = category_telephones.add_new_default_feature("tags", feature_hardware.id, "body", {:set_tags => ["stylish", "sharp", "robust", "thick"]})    
    feature_hardware_ = category_telephones.add_new_default_feature("binary", feature_hardware.id, "ambient_light_sensor")
    feature_hardware_ = category_telephones.add_new_default_feature("tags", feature_hardware.id, "hardware_buttons", {:set_tags => ["call", "hang", "menu", "home", "mute", "volume", "lock"]})    
    feature_hardware_ = category_telephones.add_new_default_feature("binary", feature_hardware.id, "accelerometer")
    
    # communication
    feature_communication = category_telephones.add_new_default_feature("header", nil, "communication")
    feature_communication_voice_activation = category_telephones.add_new_default_feature("binary", feature_communication.id, "voice_activation")
    feature_communication_messaging = category_telephones.add_new_default_feature("tag", feature_communication.id, "messaging", {:set_tags => ["SMS", "MMS", "IM", "Social Network"]})
    
    # Geolocation    
    feature_geolocalisation = category_telephones.add_new_default_feature("binary", nil, "geolocation")
    feature_geolocalisation_assisted = category_telephones.add_new_default_feature("binary", feature_geolocalisation.id, "assisted")
    feature_geolocalisation_turn_by_turn_gps_navigation = category_telephones.add_new_default_feature("binary", feature_geolocalisation.id, "turn_by_turn_gps_navigation")
    feature_geolocalisation_picture_geotagging = category_telephones.add_new_default_feature("binary", feature_geolocalisation.id, "picture_geotagging")
    feature_geolocalisation_navigation_app = category_telephones.add_new_default_feature("tags", feature_geolocalisation.id, "navigation_app", {:set_tags => ["VZ Navigator", "GoogleMaps"]})
    
    # Connectivity
    feature_connectivity = category_telephones.add_new_default_feature("header", nil, "connectivity")
    feature_connectivity_type_networks = category_telephones.add_new_default_feature("tags", feature_connectivity.id, "type_networks", {:set_tags => ["Tri-Band", "Quad-Band"]})
    feature_connectivity_broadband = category_telephones.add_new_default_feature("tags", feature_connectivity.id, "broadband", {:set_tags => ["3G", "Edge", "3G EDOR"]})
    feature_connectivity_wifi = category_telephones.add_new_default_feature("binary", feature_connectivity.id, "wifi")
    feature_connectivity_wifi_type = category_telephones.add_new_default_feature("tags", feature_connectivity_wifi.id, "type", {:set_tags => ["b", "g", "n"]})
    feature_connectivity_bluetooth = category_telephones.add_new_default_feature("binary", feature_connectivity.id, "bluetooth")
    feature_connectivity_bluetooth_type = category_telephones.add_new_default_feature("tags", feature_connectivity_bluetooth.id, "type", {:set_tags => ["1.0", "2.0", "Stereo"]})
    feature_connectivity_usb = category_telephones.add_new_default_feature("binary", feature_connectivity.id, "usb")

    # Memory
    feature_memory = category_telephones.add_new_default_feature("header", nil, "memory")
    feature_memory_internal = category_telephones.add_new_default_feature("numeric", feature_memory.id, "internal", {:min => 1, :max => 12, :format => "% .1f mb"})
    feature_memory_external = category_telephones.add_new_default_feature("tags", feature_memory.id, "external", {:set_tags => ["sd", "micro-sd", "sdhc", "stick", "stick micro"]})
    
    # Battery
    feature_battery = category_telephones.add_new_default_feature("header", nil, "battery")
    feature_battery_power = category_telephones.add_new_default_feature("numeric", feature_battery.id, "power", {:min => 1, :max => 9000, :format => "% .1f mAh"})
    feature_battery_talk_time = category_telephones.add_new_default_feature("numeric", feature_battery.id, "talk_time", {:min => 1, :max => 24, :format => "% .1f Hours"})
    feature_battery_standby_time = category_telephones.add_new_default_feature("numeric", feature_battery.id, "standby_time", {:min => 1, :max => 128, :format => "% .1f Hours"})
    feature_battery_video_playback_time = category_telephones.add_new_default_feature("numeric", feature_battery.id, "video_playback_time", {:min => 1, :max => 24, :format => "% .1f Hours"})
    feature_battery_music_playback_time = category_telephones.add_new_default_feature("numeric", feature_battery.id, "music_playback_time", {:min => 1, :max => 48, :format => "% .1f Hours"})
    
    # Operating System
    feature_operating_system = category_telephones.add_new_default_feature("tags", nil, "operating_system", {:set_tags => ["Apple", "Google Android", "Symbian", "Microsoft", "MOTOMAGX", "BlackBerry"]})

    # Internet & Productivity
    feature_internet = category_telephones.add_new_default_feature("header", nil, "internet")
    feature_internet_email = category_telephones.add_new_default_feature("binary", feature_internet.id, "email")
    feature_internet_email_providers = category_telephones.add_new_default_feature("tags", feature_internet_email.id, "providers", {:set_tags => ["MS Outlook", "Gmail", "Yahoo"]})
    feature_internet_email_nb_clients = category_telephones.add_new_default_feature("tag", feature_internet_email.id, "nb_clients", {:set_tags => ["single", "multiple"]})
    feature_internet_email_attachments = category_telephones.add_new_default_feature("tags", feature_internet_email.id, "attachments", {:set_tags => ["pdf", "image", "video", "music", "office", "google docs"]})
    feature_internet_services = category_telephones.add_new_default_feature("tags", feature_internet.id, "services", {:set_tags => ["google maps", "One touch google search", "flick", "twitter", "chat", "voip"]})
    feature_internet_browser = category_telephones.add_new_default_feature("tags", feature_internet.id, "browser", {:set_tags => ["safari", "skyfire", "webkit"]})
    feature_internet_navigation = category_telephones.add_new_default_feature("tags", feature_internet.id, "navigation", {:set_tags => ["touch-screen", "fast-scroll-wheel"]})
    feature_internet_page_zoom = category_telephones.add_new_default_feature("tags", feature_internet.id, "page_zoom", {:set_tags => ["multi-touch", "button"]})

    # Camera
    feature_camera = category_telephones.add_new_default_feature("binary", il, "camera")
    feature_camera_nb_pixel = category_telephones.add_new_default_feature("numeric", feature_camera.id, "nb_pixel", {:min => 1, :max => 12, :format => "% .1f mpx"})
    feature_camera_features = category_telephones.add_new_default_feature("tags", feature_camera.id, "features", {:set_tags => ["autofocus", "led flash", "% .1f Zeiss Lens"]})
    feature_camera_zoom = category_telephones.add_new_default_feature("binary", feature_camera.id, "zoom")
    feature_camera_zoom_range = category_telephones.add_new_default_feature("numeric", feature_camera_zoom.id, "range", {:min => 1, :max => 20, :format => "% .1f time"})
    feature_camera_zoom_type = category_telephones.add_new_default_feature("tag", feature_camera_zoom.id, "type", {:set_tags => ["optical", "numeric"]})
    feature_camera_video = category_telephones.add_new_default_feature("binary", feature_camera.id, "video")
    feature_camera_video_features = category_telephones.add_new_default_feature("tags", feature_camera_video.id, "features", {:set_tags => ["HD", "DVD", "16x9", "30FPS", "flash with continuous lighting"]})
    feature_camera_aperture = category_telephones.add_new_default_feature("numeric", feature_camera.id, "aperture", {:min => 1, :max => 20, :format => "% .1f time"})
    feature_camera_focal_length = category_telephones.add_new_default_feature("numeric", feature_camera.id, "focal_length", {:min => 1, :max => 20, :format => "% .1f time"})
    
    # media
    feature_media = category_telephones.add_new_default_feature("header", nil, "media")
    feature_media_video_playback = category_telephones.add_new_default_feature("binary", feature_media.id, "video_playback")
    feature_media_video_playback_services = category_telephones.add_new_default_feature("tags", feature_media_video_playback.id, "services", {:set_tags => ["Youtube", "iTunes", "Blackberry" "Media Center", "Roxio Media Manager", "HD"]})
    feature_media_video_playback_formats = category_telephones.add_new_default_feature("tags", feature_media_video_playback.id, "formats", {:set_tags => ["Flash", "MPEG-4", "AVC/H.264", "up to 30 fps" "up to VGA resolution", "Windows Media (WMV9)", "CIF @ 30 fps"]})
    feature_media_music_player = category_telephones.add_new_default_feature("binary", feature_media.id, "music_player")
    feature_media_music_player_formats = category_telephones.add_new_default_feature("tags", feature_media_music_player.id, "formats", {:set_tags => ["MP3", "AAC", "eAAC" "eAAC+", "WMA", "WAV", "AIFF", "Apple Lossless"]})
    feature_media_radio = category_telephones.add_new_default_feature("binary", feature_media.id, "radio")
    feature_media_radio_details = category_telephones.add_new_default_feature("tags", feature_media_radio.id, "details", {:set_tags => ["FM", "RDS"]})
    feature_media_media_center = category_telephones.add_new_default_feature("binary", feature_media.id, "media_center")
    feature_media_media_center_features = category_telephones.add_new_default_feature("tags", feature_media_media_center.id, "features", {:set_tags => ["UPnP support", "Media Synchronizing"]})
    feature_media_headphone_plug_3_5mm = category_telephones.add_new_default_feature("binary", feature_media.id, "headphone_plug_3.5mm")
    feature_media_tv_out_support = category_telephones.add_new_default_feature("binary", feature_media.id, "tv-out support")
    feature_media_tv_out_support_format = category_telephones.add_new_default_feature("tags", feature_media.id, "tv-out support/format", {:set_tags => ["PAL", "NTSC"]})
    
    # Application
    feature_application_store = category_telephones.add_new_default_feature("binary", nil, "application_store")
    feature_application_store_direct_app_download = category_telephones.add_new_default_feature("binary", feature_application_store.id, "direct_app_download")
    
    # ------------------------------------------------------------------------------------
    # Items
    # ------------------------------------------------------------------------------------
    
    category_telephones.add_new_default_product("nokia n95").set_values({
      feature_brand.id => "Nokia",
      feature_price_interval.id => "400; 430",
      feature_released_on.id => "2/10/2007",
      feature_released_on_status.id => "released",
      feature_general_nickname.id => "N95",
      feature_general_carriers.id => ["ATT"],
      feature_general_weight.id => 170,
      feature_general_size.id => "123x32x45mn",
      feature_hardware_screen_type.id => ["touch"],
      feature_hardware_screen_nb_colors.id => 2,
      feature_hardware_virtual_keyboard.id => DomainBinary.no,
      feature_hardware_ambient_light_sensor.id => DomainBinary.no,
      feature_hardware_accelerometer.id => DomainBinary.no,
      feature_communication_voice_activation.id => DomainBinary.yes,
      feature_geolocation.id => DomainBinary.yes,
      feature_geolocation_assisted.id => DomainBinary.yes,
      feature_geolocation_turn_by_turn_gps_navigation.id => DomainBinary.yes,
      feature_geolocation_picture_geotagging.id => DomainBinary.no,
      feature_geolocation_navigation_app.id => ["VZ Navigator"],
      feature_connectivity_wifi.id => DomainBinary.yes
    })
    
=begin
    category_telephones.add_new_default_product("nokia n95").set_values({
      "brand" => "Nokia",
      "price_interval" => "430;450",
      "released_on" => "2/10/2007",
      "released_on/status" => "released",
      "general/nickname" => "N95",
      "general/carriers" => "ATT",
      "general/weight" => 170,
      "general/size" => "123x32x45mn",
      "hardware/screen/type" => ,
      "hardware/screen/resolution" => ,
      "hardware/screen/nb_colors" => ,
      "hardware/virtual_keyboard" => ,
      "hardware/virtual_keyboard/mode" => ,
      "hardware/form_factor" => ,
      "hardware/body" => ,
      "hardware/ambient light sensor" => ,
      "hardware/hardware buttons" => ,
      "hardware/accelerometer" => ,
      "communication/voice_activation" => ,
      "communication/messaging" => ,
      "geolocation" => ,
      "geolocation/assisted" => ,
      "geolocation/Turn-by-turn GPS navigation" => ,
      "geolocation/Picture geotagging" => ,
      "geolocation/Navigation app" => ,
      "connectivity/type_networks" => ,
      "connectivity/broadband" => ,
      "connectivity/wifi" => ,
      "connectivity/wifi/type" => ,
      "connectivity/bluetooth" => ,
      "connectivity/bluetooth/type" => ,
      "connectivity/usb" => ,
      "memory/internal" => ,
      "memory/external" => ,
      "battery/power" => ,
      "battery/talk_time" => ,
      "battery/standby_time" => ,
      "battery/video_playback_time" => ,
      "battery/music_playback_time" => ,
      "operating_system" => ,
      "internet/email" => ,
      "internet/email/providers" => ,
      "internet/email/nb_clients" => ,
      "internet/email/attachments" => ,
      "internet/services" => ,
      "internet/browser" => ,
      "internet/navigation" => ,
      "internet/page_zoom" => ,
      "camera" => ,
      "camera/nb_pixel" => ,
      "camera/features" => ,
      "camera/zoom/range" => ,
      "camera/zoom/type" => ,
      "camera/video" => ,
      "camera/video/features" => ,
      "camera/aperture" => ,
      "camera/focal_length" => ,
      "media/video_playback" => ,
      "media/video_playback/services" => ,
      "media/video_playback/formats" => ,
      "media/music_player" => ,
      "media/music_player/formats" => ,
      "media/radio" => ,
      "media/radio/details" => ,
      "media/media_center" => ,
      "media/media_center/features" => ,
      "media/headphone_plug_3.5mm" => ,
      "media/tv-out support" => ,
      "media/tv-out support/format" => ,
      "application_store" => ,
      "direct_app_download" => 
    })
    
=end    


 
  end
  
end

