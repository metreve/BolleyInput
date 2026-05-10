export type Snapshot = {
	History: { { Data: any, TimeStamp: number } },
	SaveHistory: (Data: any, TimeStamp: number) -> (),
	Cleanup: () -> (),
}
return function(Length)
	local History = table.create(10)

	local function SaveHistory(data, Timestamp)
		if #History == Length then
			table.remove(History, 1)
		end

		table.insert(History, {
			["Data"] = data,
			["Timestamp"] = Timestamp,
		})
	end
	local function Cleanup()
		table.clear(History)
		History = nil
		SaveHistory = nil
	end
	return { History = History, SaveHistory = SaveHistory, Cleanup = Cleanup }
end
