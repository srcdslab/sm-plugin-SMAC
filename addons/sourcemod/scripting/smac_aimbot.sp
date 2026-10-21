/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team 
    Copyright (C) 2007-2011 CodingDirect LLC
   
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required

/* SM Includes */
#include <sourcemod>
#include <sdktools>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC Aimbot Detector",
    author =        SMAC_AUTHOR,
    description =   "Analyzes clients to detect aimbots",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define AIM_ANGLE_CHANGE	45.0	// Max angle change that a player should snap
#define AIM_BAN_MIN			4		// Minimum number of detections before an auto-ban is allowed
#define AIM_MIN_DISTANCE	200.0	// Minimum distance acceptable for a detection.

ConVar g_hCvarAimbotBan = null;
StringMap g_IgnoreWeapons = null;

float g_fEyeAngles[MAXPLAYERS+1][64][3];
int g_iEyeIndex[MAXPLAYERS+1];

int g_iAimDetections[MAXPLAYERS+1];
int g_iAimbotBan = 0;
int g_iMaxAngleHistory;

/* Plugin Functions */
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // Convars.
    g_hCvarAimbotBan = SMAC_CreateConVar("smac_aimbot_ban", "0", "Number of aimbot detections before a player is banned. Minimum allowed is 4. (0 = Never ban)", 0, true, 0.0);
    OnSettingsChanged(g_hCvarAimbotBan, "", "");
    g_hCvarAimbotBan.AddChangeHook(OnSettingsChanged);

    // Store no more than 500ms worth of angle history.
    if ((g_iMaxAngleHistory = TIME_TO_TICK(0.5)) > sizeof(g_fEyeAngles[]))
    {
        g_iMaxAngleHistory = sizeof(g_fEyeAngles[]);
    }

    // Weapons to ignore when analyzing.
    g_IgnoreWeapons = new StringMap();

    switch (SMAC_GetGameType())
    {
        case Game_CSS:
        {
            g_IgnoreWeapons.SetValue("weapon_knife", 1);
        }
        case Game_CSGO:
        {
            g_IgnoreWeapons.SetValue("weapon_knife", 1);
            g_IgnoreWeapons.SetValue("weapon_taser", 1);
        }
        case Game_DODS:
        {
            g_IgnoreWeapons.SetValue("weapon_spade", 1);
            g_IgnoreWeapons.SetValue("weapon_amerknife", 1);
        }
        case Game_TF2:
        {
            g_IgnoreWeapons.SetValue("tf_weapon_bottle", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_sword", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_wrench", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_robot_arm", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_fists", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_bonesaw", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_fireaxe", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_bat", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_bat_wood", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_bat_fish", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_club", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_shovel", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_knife", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_stickbomb", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_katana", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_flamethrower", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_slap", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_buff_item", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_parachute", 1); 
            g_IgnoreWeapons.SetValue("tf_weapon_breakable_sign", 1);
            g_IgnoreWeapons.SetValue("tf_wearable_demoshield", 1); 
            g_IgnoreWeapons.SetValue("tf_wearable_razorback", 1); 
            g_IgnoreWeapons.SetValue("tf_wearable", 1); 
            g_IgnoreWeapons.SetValue("tf_weapon_rocketpack", 1); 
            g_IgnoreWeapons.SetValue("tf_weapon_lunchbox_drink", 1);
            g_IgnoreWeapons.SetValue("tf_weapon_lunchbox", 1); 
            g_IgnoreWeapons.SetValue("saxxy", 1); 
        }
        case Game_HL2DM:
        {
            g_IgnoreWeapons.SetValue("weapon_crowbar", 1);
            g_IgnoreWeapons.SetValue("weapon_stunstick", 1);
        }
        case Game_ZPS:
        {
            g_IgnoreWeapons.SetValue("weapon_torque", 1);
            g_IgnoreWeapons.SetValue("weapon_tireiron", 1);
            g_IgnoreWeapons.SetValue("weapon_crowbar", 1);
            g_IgnoreWeapons.SetValue("weapon_spanner", 1);
            g_IgnoreWeapons.SetValue("weapon_sledgehammer", 1);
            g_IgnoreWeapons.SetValue("weapon_shovel", 1);
            g_IgnoreWeapons.SetValue("weapon_racket", 1);
            g_IgnoreWeapons.SetValue("weapon_pot", 1);
            g_IgnoreWeapons.SetValue("weapon_plank", 1);
            g_IgnoreWeapons.SetValue("weapon_pipewrench", 1);   
            g_IgnoreWeapons.SetValue("weapon_pipe", 1);
            g_IgnoreWeapons.SetValue("weapon_phone", 1);
            g_IgnoreWeapons.SetValue("weapon_meatcleaver", 1);
            g_IgnoreWeapons.SetValue("weapon_machete", 1);
            g_IgnoreWeapons.SetValue("weapon_keyboard", 1);
            g_IgnoreWeapons.SetValue("weapon_ied", 1);
            g_IgnoreWeapons.SetValue("weapon_golf", 1);
            g_IgnoreWeapons.SetValue("weapon_fryingpan", 1);
            g_IgnoreWeapons.SetValue("weapon_emptyhand", 1);
            g_IgnoreWeapons.SetValue("weapon_carrierarms", 1);
            g_IgnoreWeapons.SetValue("weapon_broom", 1);
            g_IgnoreWeapons.SetValue("weapon_bat_wood", 1);
            g_IgnoreWeapons.SetValue("weapon_bat_aluminum", 1);
            g_IgnoreWeapons.SetValue("weapon_chair", 1);
            g_IgnoreWeapons.SetValue("weapon_baguette", 1);
            g_IgnoreWeapons.SetValue("weapon_barricade", 1);
            g_IgnoreWeapons.SetValue("weapon_axe", 1);
            g_IgnoreWeapons.SetValue("weapon_arms", 1);
            g_IgnoreWeapons.SetValue("weapon_wrench", 1);
        }
    }

    // Hooks.
    HookEntityOutput("trigger_teleport", "OnEndTouch", Teleport_OnEndTouch);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    if (SMAC_GetGameType() == Game_TF2)
    {
        HookEvent("player_death", TF2_Event_PlayerDeath, EventHookMode_Post);
    }
    else if (!HookEventEx("entity_killed", Event_EntityKilled, EventHookMode_Post))
    {
        HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    }
}

public void OnClientPutInServer(int client)
{
    if (IsClientNew(client))
    {
        g_iAimDetections[client] = 0;
        Aimbot_ClearAngles(client);
    }
}

public void OnSettingsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    int iNewValue = convar.IntValue;
    
    if (iNewValue > 0 && iNewValue < AIM_BAN_MIN)
    {
        convar.IntValue = AIM_BAN_MIN;
        return;
    }

    g_iAimbotBan = iNewValue;
}

public void Teleport_OnEndTouch(const char[] output, int caller, int activator, float delay)
{
    /* A client is being teleported in the map. */
    if (IS_CLIENT(activator) && IsClientConnected(activator))
    {
        Aimbot_ClearAngles(activator);
        CreateTimer(0.1 + delay, Timer_ClearAngles, GetClientUserId(activator), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    
    if (IS_CLIENT(client))
    {
        Aimbot_ClearAngles(client);
        CreateTimer(0.1, Timer_ClearAngles, userid, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    char sWeapon[32], dummy;
    //GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
    event.GetString("weapon", sWeapon, sizeof(sWeapon));

    if (g_IgnoreWeapons.GetValue(sWeapon, dummy))
    {
        return Plugin_Continue;
    }
        
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (IS_CLIENT(victim) && IS_CLIENT(attacker) && victim != attacker && IsClientInGame(victim) && IsClientInGame(attacker))
    {
        float vVictim[3], vAttacker[3];
        GetClientAbsOrigin(victim, vVictim);
        GetClientAbsOrigin(attacker, vAttacker);

        if (GetVectorDistance(vVictim, vAttacker) >= AIM_MIN_DISTANCE)
        {
            Aimbot_AnalyzeAngles(attacker);
        }
    }
    return Plugin_Continue;
}

public Action Event_EntityKilled(Event event, const char[] name, bool dontBroadcast)
{
    /* (OB Only) Inflictor support lets us ignore non-bullet weapons. */
    int victim = event.GetInt("entindex_killed");
    int attacker = event.GetInt("entindex_attacker");
    int inflictor = event.GetInt("entindex_inflictor");
    
    if (IS_CLIENT(victim) && IS_CLIENT(attacker) && victim != attacker && attacker == inflictor && IsClientInGame(victim) && IsClientInGame(attacker))
    {
        char sWeapon[32], dummy;
        GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
        
        if (g_IgnoreWeapons.GetValue(sWeapon, dummy))
        {
            return Plugin_Continue;
        }
        
        float vVictim[3], vAttacker[3];
        GetClientAbsOrigin(victim, vVictim);
        GetClientAbsOrigin(attacker, vAttacker);
        
        if (GetVectorDistance(vVictim, vAttacker) >= AIM_MIN_DISTANCE)
        {
            Aimbot_AnalyzeAngles(attacker);
        }
    }
    return Plugin_Continue;
}

public Action TF2_Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    /* TF2 custom death event */
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int inflictor = event.GetInt("inflictor_entindex");

    if (IS_CLIENT(victim) && IS_CLIENT(attacker) && victim != attacker && attacker == inflictor && IsClientInGame(victim) && IsClientInGame(attacker))
    {
        char sWeapon[32], dummy;
        GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));

        if (g_IgnoreWeapons.GetValue(sWeapon, dummy))
        {
            return Plugin_Continue;
        }
        
        float vVictim[3], vAttacker[3];
        GetClientAbsOrigin(victim, vVictim);
        GetClientAbsOrigin(attacker, vAttacker);

        if (GetVectorDistance(vVictim, vAttacker) >= AIM_MIN_DISTANCE)
        {
            Aimbot_AnalyzeAngles(attacker);
        }
    }
    return Plugin_Continue;
}

public Action Timer_ClearAngles(Handle timer, any userid)
{
    /* Delayed because the client's angles can sometimes "spin" after being teleported. */
    int client = GetClientOfUserId(userid);
    
    if (IS_CLIENT(client))
    {
        Aimbot_ClearAngles(client);
    }
    
    return Plugin_Stop;
}

public Action Timer_DecreaseCount(Handle timer, any userid)
{
    /* Decrease the detection count by 1. */
    int client = GetClientOfUserId(userid);
    
    if (IS_CLIENT(client) && g_iAimDetections[client])
    {
        g_iAimDetections[client]--;
    }
    
    return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    g_fEyeAngles[client][g_iEyeIndex[client]] = angles;

    if (++g_iEyeIndex[client] == g_iMaxAngleHistory)
    {
        g_iEyeIndex[client] = 0;
    }
        
    return Plugin_Continue;
}

void Aimbot_AnalyzeAngles(int client)
{
    /* Analyze the client to see if their angles snapped. */
    float vLastAngles[3], vAngles[3], fAngleDiff;
    int idx = g_iEyeIndex[client];
    
    for (int i = 0; i < g_iMaxAngleHistory; i++)
    {
        if (idx == g_iMaxAngleHistory)
        {
            idx = 0;
        }
            
        if (IsVectorZero(g_fEyeAngles[client][idx]))
        {
            break;
        }
        
        // Nothing to compare on the first iteration.
        if (i == 0)
        {
            vLastAngles = g_fEyeAngles[client][idx];
            idx++;
            continue;
        }
        
        vAngles = g_fEyeAngles[client][idx];
        fAngleDiff = GetVectorDistance(vLastAngles, vAngles);
        
        // If the difference is being reported higher than 180, get the 'real' value.
        if (fAngleDiff > 180)
        {
            fAngleDiff = FloatAbs(fAngleDiff - 360);
        }

        if (fAngleDiff > AIM_ANGLE_CHANGE)
        {
            Aimbot_Detected(client, fAngleDiff);
            break;
        }
        
        vLastAngles = vAngles;
        idx++;
    }
}

void Aimbot_Detected(int client, const float deviation)
{
    // Extra checks must be done here because of data coming from two events.
    if (IsFakeClient(client) || !IsPlayerAlive(client))
    {
        return;
    }
    
    switch (SMAC_GetGameType())
    {
        case Game_L4D:
        {
            if (GetClientTeam(client) != 2 || L4D_IsSurvivorBusy(client))
            {
                return;
            }
        }
        case Game_L4D2:
        {
            if (GetClientTeam(client) != 2 || L4D2_IsSurvivorBusy(client))
            {    
                return;
            }
        }
        case Game_ND:
        {
            if (ND_IsPlayerCommander(client))
            {
                return;
            }
        }
    }
    
    char sWeapon[32];
    GetClientWeapon(client, sWeapon, sizeof(sWeapon));
    
    KeyValues info = new KeyValues("");
    info.SetNum("detection", g_iAimDetections[client]);
    info.SetFloat("deviation", deviation);
    info.SetString("weapon", sWeapon);
    
    if (SMAC_CheatDetected(client, Detection_Aimbot, info) == Plugin_Continue)
    {
        // Expire this detection after 10 minutes.
        CreateTimer(600.0, Timer_DecreaseCount, GetClientUserId(client));
        
        // Ignore the first detection as it's just as likely to be a false positive.
        if (++g_iAimDetections[client] > 1)
        {
            SMAC_PrintAdminNotice("%t", "SMAC_AimbotDetected", client, g_iAimDetections[client], deviation, sWeapon);
            SMAC_LogAction(client, "is suspected of using an aimbot. (Detection #%i | Deviation: %.0f° | Weapon: %s)", g_iAimDetections[client], deviation, sWeapon);
            
            if (g_iAimbotBan && g_iAimDetections[client] >= g_iAimbotBan)
            {
                SMAC_LogAction(client, "was banned for using an aimbot.");
                SMAC_Ban(client, "Aimbot Detected");
            }
        }
    }
    
    delete info;
}

void Aimbot_ClearAngles(int client)
{
    /* Clear angle history and reset the index. */
    g_iEyeIndex[client] = 0;
    
    for (int i = 0; i < g_iMaxAngleHistory; i++)
    {
        ZeroVector(g_fEyeAngles[client][i]);
    }
}
