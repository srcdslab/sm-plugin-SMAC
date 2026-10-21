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
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC Command Monitor",
    author =        SMAC_AUTHOR,
    description =   "Blocks general command exploits",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define MAX_CMD_NAME_LEN PLATFORM_MAX_PATH

enum ActionType {
    Action_Block = 0,
    Action_Ban,
    Action_Kick
};

StringMap g_hBlockedCmds = null;
StringMap g_hIgnoredCmds = null;
int g_iCmdSpamLimit = 30;
int g_iCmdCount[MAXPLAYERS+1] = {0, ...};
ConVar g_hCvarCmdSpam = null;
ConVar g_hCvarCmdSpmKick = null;

/* Plugin Functions */
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");
    
    // Convars.
    g_hCvarCmdSpam = SMAC_CreateConVar("smac_antispam_cmds", "20", "Amount of commands allowed per second. (0 = Disabled)", 0, true, 0.0);
    g_hCvarCmdSpmKick = SMAC_CreateConVar("smac_anticmdspam_kick", "1", "Choose to kick or simply notify that commands are being spammed. (0 = Notify  1 = Kick)", 0, true, 0.0, true, 1.0);
    OnSettingsChanged(g_hCvarCmdSpam, "", "");
    g_hCvarCmdSpam.AddChangeHook(OnSettingsChanged);

    // Hooks.
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
    
    switch (SMAC_GetGameType())
    {
        case Game_INS:
        {
            AddCommandListener(Command_Say, "say2");
        }
        case Game_ND:
        {
            AddCommandListener(Command_Say, "say_squad");
        }
    }

    // Exploitable needed commands.  Sigh....
    AddCommandListener(Command_BlockEntExploit, "ent_create");
    AddCommandListener(Command_BlockEntExploit, "ent_fire");

    // L4D2 uses this for confogl.
    if (SMAC_GetGameType() != Game_L4D2)
    {
        AddCommandListener(Command_BlockEntExploit, "give");
    }

    // Init...
    g_hBlockedCmds = new StringMap();
    g_hIgnoredCmds = new StringMap();

    // Add commands to block list.
    g_hBlockedCmds.SetValue("ai_test_los", Action_Block);
    g_hBlockedCmds.SetValue("cl_fullupdate", Action_Block);
    g_hBlockedCmds.SetValue("dbghist_addline", Action_Block);
    g_hBlockedCmds.SetValue("dbghist_dump", Action_Block);
    g_hBlockedCmds.SetValue("drawcross", Action_Block);
    g_hBlockedCmds.SetValue("drawline", Action_Block);
    g_hBlockedCmds.SetValue("dump_entity_sizes", Action_Block);
    g_hBlockedCmds.SetValue("dump_globals", Action_Block);
    g_hBlockedCmds.SetValue("dump_panels", Action_Block);
    g_hBlockedCmds.SetValue("dump_terrain", Action_Block);
    g_hBlockedCmds.SetValue("dumpcountedstrings", Action_Block);
    g_hBlockedCmds.SetValue("dumpentityfactories", Action_Block);
    g_hBlockedCmds.SetValue("dumpeventqueue", Action_Block);
    g_hBlockedCmds.SetValue("dumpgamestringtable", Action_Block);
    g_hBlockedCmds.SetValue("editdemo", Action_Block);
    g_hBlockedCmds.SetValue("endround", Action_Block);
    g_hBlockedCmds.SetValue("groundlist", Action_Block);
    g_hBlockedCmds.SetValue("listdeaths", Action_Block);
    g_hBlockedCmds.SetValue("listmodels", Action_Block);
    g_hBlockedCmds.SetValue("map_showspawnpoints", Action_Block);
    g_hBlockedCmds.SetValue("mem_dump", Action_Block);
    g_hBlockedCmds.SetValue("mp_dump_timers", Action_Block);
    g_hBlockedCmds.SetValue("npc_ammo_deplete", Action_Block);
    g_hBlockedCmds.SetValue("npc_heal", Action_Block);
    g_hBlockedCmds.SetValue("npc_speakall", Action_Block);
    g_hBlockedCmds.SetValue("npc_thinknow", Action_Block);
    g_hBlockedCmds.SetValue("physics_budget", Action_Block);
    g_hBlockedCmds.SetValue("physics_debug_entity", Action_Block);
    g_hBlockedCmds.SetValue("physics_highlight_active", Action_Block);
    g_hBlockedCmds.SetValue("physics_report_active", Action_Block);
    g_hBlockedCmds.SetValue("physics_select", Action_Block);
    g_hBlockedCmds.SetValue("report_entities", Action_Block);
    g_hBlockedCmds.SetValue("report_simthinklist", Action_Block);
    g_hBlockedCmds.SetValue("report_touchlinks", Action_Block);
    g_hBlockedCmds.SetValue("respawn_entities", Action_Block);
    g_hBlockedCmds.SetValue("rr_reloadresponsesystems", Action_Block);
    g_hBlockedCmds.SetValue("scene_flush", Action_Block);
    g_hBlockedCmds.SetValue("snd_digital_surround", Action_Block);
    g_hBlockedCmds.SetValue("snd_restart", Action_Block);
    g_hBlockedCmds.SetValue("soundlist", Action_Block);
    g_hBlockedCmds.SetValue("soundscape_flush", Action_Block);
    g_hBlockedCmds.SetValue("sv_benchmark_force_start", Action_Block);
    g_hBlockedCmds.SetValue("sv_findsoundname", Action_Block);
    g_hBlockedCmds.SetValue("sv_soundemitter_filecheck", Action_Block);
    g_hBlockedCmds.SetValue("sv_soundemitter_flush", Action_Block);
    g_hBlockedCmds.SetValue("sv_soundscape_printdebuginfo", Action_Block);
    g_hBlockedCmds.SetValue("wc_update_entity", Action_Block);
    g_hBlockedCmds.SetValue("ping", Action_Block);
    
    g_hBlockedCmds.SetValue("changelevel", Action_Ban);
    
    g_hBlockedCmds.SetValue("speed.toggle", Action_Kick);
    
    // Add game specific commands to block list.
    switch (SMAC_GetGameType())
    {
        case Game_L4D:
        {
            g_hBlockedCmds.SetValue("demo_returntolobby", Action_Block);
            g_hIgnoredCmds.SetValue("choose_closedoor", true);
            g_hIgnoredCmds.SetValue("choose_opendoor", true);
        }
        case Game_L4D2:
        {
            g_hIgnoredCmds.SetValue("choose_closedoor", true);
            g_hIgnoredCmds.SetValue("choose_opendoor", true);
        }
        case Game_ND:
        {
            g_hIgnoredCmds.SetValue("bitcmd", true);
            g_hIgnoredCmds.SetValue("sg", true);
        }
        case Game_CSGO:
        {
            g_hIgnoredCmds.SetValue("snd_setsoundparam", true);
        }
    }

    // Add commands to ignore list.
    g_hIgnoredCmds.SetValue("buy", true);
    g_hIgnoredCmds.SetValue("buyammo1", true);
    g_hIgnoredCmds.SetValue("buyammo2", true);
    g_hIgnoredCmds.SetValue("setpause", true);
    g_hIgnoredCmds.SetValue("spec_mode", true);
    g_hIgnoredCmds.SetValue("spec_next", true);
    g_hIgnoredCmds.SetValue("spec_prev", true);
    g_hIgnoredCmds.SetValue("unpause", true);
    g_hIgnoredCmds.SetValue("use", true);
    g_hIgnoredCmds.SetValue("vban", true);
    g_hIgnoredCmds.SetValue("vmodenable", true);

    CreateTimer(1.0, Timer_ResetCmdCount, _, TIMER_REPEAT);

    AddCommandListener(Command_CommandListener);

    RegAdminCmd("smac_addcmd", Command_AddCmd, ADMFLAG_ROOT, "Block a command.");
    RegAdminCmd("smac_addignorecmd", Command_AddIgnoreCmd, ADMFLAG_ROOT, "Ignore a command.");
    RegAdminCmd("smac_removecmd", Command_RemoveCmd, ADMFLAG_ROOT, "Unblock a command.");
    RegAdminCmd("smac_removeignorecmd", Command_RemoveIgnoreCmd, ADMFLAG_ROOT, "Unignore a command.");
}

public Action Command_AddCmd(int client,int args)
{
    if (args == 2)
    {
        char sCommand[MAX_CMD_NAME_LEN], sAction[8];

        GetCmdArg(1, sCommand, sizeof(sCommand));
        StringToLower(sCommand);

        GetCmdArg(2, sAction, sizeof(sAction));

        ActionType cAction = Action_Block;
        
        switch (StringToInt(sAction))
        {
            case 1:
            {
                cAction = Action_Ban;
            }
            case 2:
            {
                cAction = Action_Kick;
            }
        }
        
        g_hBlockedCmds.SetValue(sCommand, cAction);
        ReplyToCommand(client, "%s has been added.", sCommand);
        
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "Usage: smac_addcmd <cmd> <action>");
    return Plugin_Handled;
}

public Action Command_AddIgnoreCmd(int client,int args)
{
    if (args == 1)
    {
        char sCommand[MAX_CMD_NAME_LEN];
        
        GetCmdArg(1, sCommand, sizeof(sCommand));
        StringToLower(sCommand);
        
        g_hIgnoredCmds.SetValue(sCommand, true);
        ReplyToCommand(client, "%s has been added.", sCommand);
        
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "Usage: smac_addignorecmd <cmd>");
    return Plugin_Handled;
}

public Action Command_RemoveCmd(int client,int args)
{
    if (args == 1)
    {
        char sCommand[MAX_CMD_NAME_LEN];
        
        GetCmdArg(1, sCommand, sizeof(sCommand));
        StringToLower(sCommand);

        if (g_hBlockedCmds.Remove(sCommand))
        {
            ReplyToCommand(client, "%s has been removed.", sCommand);
        }
        else
        {
            ReplyToCommand(client, "%s was not found.", sCommand);
        }
        
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "Usage: smac_removecmd <cmd>");
    return Plugin_Handled;
}

public Action Command_RemoveIgnoreCmd(int client,int args)
{
    if (args == 1)
    {
        char sCommand[MAX_CMD_NAME_LEN];
        
        GetCmdArg(1, sCommand, sizeof(sCommand));
        StringToLower(sCommand);
        
        if (g_hIgnoredCmds.Remove(sCommand))
        {
            ReplyToCommand(client, "%s has been removed.", sCommand);
        }
        else
        {
            ReplyToCommand(client, "%s was not found.", sCommand);
        }
        
        return Plugin_Handled;
    }
    
    ReplyToCommand(client, "Usage: smac_removeignorecmd <cmd>");
    return Plugin_Handled;
}

public Action Command_Say(int client, const char[] command,int args)
{
    if (!IS_CLIENT(client))
        return Plugin_Continue;

    int iSpaceNum;
    char sMsg[256], sChar;
    int iLen = GetCmdArgString(sMsg, sizeof(sMsg));
    
    for (int i = 0; i < iLen; i++)
    {
        sChar = sMsg[i];
        
        if (sChar == ' ')
        {
            if (iSpaceNum++ >= 64)
            {
                PrintToChat(client, "%t", "SMAC_SayBlock");
                return Plugin_Stop;
            }
        }
            
        if (sChar < 32 && !IsCharMB(sChar))
        {
            PrintToChat(client, "%t", "SMAC_SayBlock");
            return Plugin_Stop;
        }
    }
    
    return Plugin_Continue;
}

public Action Command_BlockEntExploit(int client, const char[] command,int args)
{
    if (!IS_CLIENT(client))
    {
        return Plugin_Continue;
    }
    
    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    
    char sArgString[512];
    
    if (GetCmdArgString(sArgString, sizeof(sArgString)) > 500)
    {
        return Plugin_Stop;
    }

    if (StrContains(sArgString, "admin") != -1 || 
        StrContains(sArgString, "alias", false) != -1 || 
        StrContains(sArgString, "logic_auto") != -1 || 
        StrContains(sArgString, "logic_autosave") != -1 || 
        StrContains(sArgString, "logic_branch") != -1 || 
        StrContains(sArgString, "logic_case") != -1 || 
        StrContains(sArgString, "logic_collision_pair") != -1 || 
        StrContains(sArgString, "logic_compareto") != -1 || 
        StrContains(sArgString, "logic_lineto") != -1 || 
        StrContains(sArgString, "logic_measure_movement") != -1 || 
        StrContains(sArgString, "logic_multicompare") != -1 || 
        StrContains(sArgString, "logic_navigation") != -1 || 
        StrContains(sArgString, "logic_relay") != -1 || 
        StrContains(sArgString, "logic_timer") != -1 || 
        StrContains(sArgString, "ma_") != -1 || 
        StrContains(sArgString, "meta") != -1 || 
        StrContains(sArgString, "mp_", false) != -1 || 
        StrContains(sArgString, "point_clientcommand") != -1 || 
        StrContains(sArgString, "point_servercommand") != -1 || 
        StrContains(sArgString, "quit", false) != -1 || 
        StrContains(sArgString, "quti") != -1 || 
        StrContains(sArgString, "rcon", false) != -1 || 
        StrContains(sArgString, "restart", false) != -1 || 
        StrContains(sArgString, "sm") != -1 || 
        StrContains(sArgString, "sv_", false) != -1 || 
        StrContains(sArgString, "taketimer") != -1)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action Command_CommandListener(int client, const char[] command,int argc)
{
    if (!IS_CLIENT(client) || (IsClientConnected(client) && IsFakeClient(client)))
    {
        return Plugin_Continue;
    }
    
    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    
    // NOTE: InternalDispatch automatically lower cases "command".
    ActionType cAction = Action_Block;
    
    if (g_hBlockedCmds.GetValue(command, cAction))
    {
        if (cAction != Action_Block)
        {
            char sArgString[192];
            GetCmdArgString(sArgString, sizeof(sArgString));
            
            KeyValues info = new KeyValues("");
            info.SetString("command", command);
            info.SetString("argstring", sArgString);
            info.SetNum("action", view_as<int>(cAction));
            
            if (SMAC_CheatDetected(client, Detection_BannedCommand, info) == Plugin_Continue)
            {
                if (cAction == Action_Ban)
                {
                    SMAC_PrintAdminNotice("%N was banned for command: %s %s", client, command, sArgString);
                    SMAC_LogAction(client, "was banned for command: %s %s", command, sArgString);
                    SMAC_Ban(client, "Command %s violation", command);
                }
                else if (cAction == Action_Kick)
                {
                    SMAC_PrintAdminNotice("%N was kicked for command: %s %s", client, command, sArgString);
                    SMAC_LogAction(client, "was kicked for command: %s %s", command, sArgString);
                    KickClient(client, "Command %s violation", command);
                }
                else
                {
                    // Do Nothing
                }
            }
            
            delete info;
        }
        
        return Plugin_Stop;
    }
    
    if (g_iCmdSpamLimit && !g_hIgnoredCmds.GetValue(command, cAction) && ++g_iCmdCount[client] > g_iCmdSpamLimit)
    {
        char sArgString[192];
        GetCmdArgString(sArgString, sizeof(sArgString));
        
        KeyValues info = new KeyValues("");
        info.SetString("command", command);
        info.SetString("argstring", sArgString);
        
        if (SMAC_CheatDetected(client, Detection_CommandSpamming, info) == Plugin_Continue)
        {
            if (g_hCvarCmdSpmKick.IntValue == 1)
            {
                SMAC_PrintAdminNotice("%N was kicked for spamming: %s %s", client, command, sArgString);
                SMAC_LogAction(client, "was kicked for spamming: %s %s", command, sArgString);
                KickClient(client, "%t", "SMAC_CommandSpamKick");
            }
            else if (g_hCvarCmdSpmKick.IntValue == 0)
            {
                SMAC_PrintAdminNotice("%N looks to be spamming commands: %s %s", client, command, sArgString);
                SMAC_LogAction(client, "looks to be spamming commands: %s %s", command, sArgString);
            }
            else
            {   
                // Do Nothing
            }
        }

        delete info;

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public Action Timer_ResetCmdCount(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iCmdCount[i] = 0;
    }

    return Plugin_Continue;
}

public void OnSettingsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    g_iCmdSpamLimit = convar.IntValue;
}
