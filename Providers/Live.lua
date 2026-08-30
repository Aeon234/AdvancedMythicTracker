local AMT = select(2, ...)

AMT.Providers.Register("live", {
	LoadKey = AMT.Challenge.Load,
	UpdateForces = AMT.Forces.Update,
	UpdateObjectives = AMT.Objectives.Update,
	UpdateDeaths = AMT.Deaths.UpdateCount,
})

AMT.Providers.Use("live")
