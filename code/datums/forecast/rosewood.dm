/datum/forecast/rosewood
	day_weather = list(/datum/particle_weather/rain_gentle = 2, /datum/particle_weather/snow_gentle = 10)
	dawn_weather = list(/datum/particle_weather/rain_gentle = 2, /datum/particle_weather/snow_gentle = 10, /datum/particle_weather/fog = 4)
	dusk_weather = list(/datum/particle_weather/fog = 8, /datum/particle_weather/snow_gentle = 20, /datum/particle_weather/snow_storm = 8)
	night_weather =  list(/datum/particle_weather/fog = 8, /datum/particle_weather/snow_gentle = 20, /datum/particle_weather/snow_storm = 8)

	temp_ranges = list(
<<<<<<< HEAD
		"dawn" = list(-5, 5),      // Cold morning
		"day" = list(5, 15),        // Cool day
		"dusk" = list(0, 10),       // Cooling evening
		"night" = list(-10, 0),     // Cold night
=======
		"dawn" = list(0, 5),      // Cold morning
		"day" = list(5, 15),        // Cool day
		"dusk" = list(3, 10),       // Cooling evening
		"night" = list(-5, 0),     // Cold night
>>>>>>> vanderlin/main
	)
