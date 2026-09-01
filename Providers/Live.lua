local AMT = select(2, ...)

AMT.Providers.Register("live", {
	Tick = AMT.Challenge.UpdateElapsed,
	LoadKey = AMT.Challenge.Load,
	UpdateForces = AMT.Forces.Update,
	UpdateObjectives = AMT.Objectives.Update,
	UpdateDeaths = AMT.Deaths.UpdateCount,
})

AMT.Providers.Use("live")
