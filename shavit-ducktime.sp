#include <shavit>

#define DUCK_AA_LOSS 0.333 // ~33.3% AA loss when ducking in air

float g_fDuckingLoss[MAXPLAYERS + 1];
float g_fLastCheck[MAXPLAYERS + 1];
bool g_bTimerRunning[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	ResetDuckData(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	ResetDuckData(client);
}

public void Shavit_OnRestart(int client)
{
	ResetDuckData(client);
}

public void Shavit_OnStage(int client, int newstage, int oldstage)
{
	if(newstage == 0)
	{
		ResetDuckData(client);
	}
}

public void Shavit_StartTimer(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}

	g_fDuckingLoss[client] = 0.0;
	g_fLastCheck[client] = GetEngineTime();
	g_bTimerRunning[client] = true;
}

public void Shavit_StopTimer(int client)
{
	g_bTimerRunning[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!g_bTimerRunning[client])
	{
		return Plugin_Continue;
	}

	float currentTime = GetEngineTime();
	float delta = currentTime - g_fLastCheck[client];

	bool isDucking = (buttons & IN_DUCK) != 0;
	bool isGrounded = (GetEntityFlags(client) & FL_ONGROUND) != 0;

	if(isDucking && !isGrounded)
	{
		g_fDuckingLoss[client] += delta * DUCK_AA_LOSS;
	}

	g_fLastCheck[client] = currentTime;

	return Plugin_Continue;
}

public Action Shavit_OnFinish_Post(int client, int style, float time, int jumps, int strafes, float sync)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Continue;
	}

	g_bTimerRunning[client] = false;

	float lostTime = g_fDuckingLoss[client];
	if(lostTime < 0.0001)
	{
		lostTime = 0.0;
	}

	PrintToChat(client, "[Timer] You lost ~%.3f seconds due to crouching.", lostTime);
	ResetDuckData(client);
	return Plugin_Continue;
}

void ResetDuckData(int client)
{
	if(client < 1 || client > MaxClients)
		return;

	g_fDuckingLoss[client] = 0.0;
	g_fLastCheck[client] = GetEngineTime();
	g_bTimerRunning[client] = false;
}
