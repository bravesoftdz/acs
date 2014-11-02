(*
  this file is a part of audio components suite v 2.3 (delphi version).
  copyright (c) 2002-2005 andrei borovsky. all rights reserved.
  see the license file for more details.
  you can contact me at acs@compiler4.net
  this is the acs for delphi (windows) version of the unit.
*)

unit acs_stdaudio;

interface

uses
  Classes, SysUtils, ACS_Types, ACS_Classes, ACS_Audio, ACS_Strings
  {$IFDEF MSWINDOWS}
  , Windows, MMSystem
  {$ELSE}
  , Soundcard
  {$ENDIF}
  ;

const
  LATENCY = 110;

type
  {$IFDEF MSWINDOWS}
  {$IFDEF FPC}
  TWaveInCapsA = WAVEINCAPSA;
  TWaveInCaps = TWaveInCapsA;

  TWaveHdr = WAVEHDR;
  {$ENDIF}

  PPWaveHdr = ^PWaveHdr;
  {$ENDIF}

  { TStdAudioOut }

  TStdAudioOut = class(TACSBaseAudioOut)
  private
    {$IFDEF MSWINDOWS}
    BlockChain: PWaveHdr;
    aBlock: Integer;
    EOC: PPWaveHdr;
    FReadChunks: Integer;
    {$ENDIF}
    _audio_fd: Integer;
    {$IFDEF MSWINDOWS}
    procedure WriteBlock(P: Pointer; Len: Integer);
    procedure AddBlockToChain(WH: PWaveHdr);
    {$ENDIF}
  protected
    function GetDeviceCount: Integer; override;
    procedure SetDevice(Ch: Integer); override;
    function GetDeviceInfo: TACSDeviceInfo; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Prepare; override;
    procedure Done; override;
    function DoOutput(Abort: Boolean): Boolean; override;
  end;

  TStdAudioIn = class(TACSBaseAudioIn)
  private
    {$IFDEF MSWINDOWS}
    BlockChain: PWaveHdr;
    FBlocksCount: Integer;
    aBlock: Integer;
    EOC: PPWaveHdr;
    {$ENDIF}
    _audio_fd: Integer;
    FOpened: Integer;
    FRecBytes: Integer;
    procedure OpenAudio;
    procedure CloseAudio;
    {$IFDEF MSWINDOWS}
    procedure NewBlock;
    procedure AddBlockToChain(WH: PWaveHdr);
    {$ENDIF}
  protected
    function GetBPS: Integer; override;
    function GetCh: Integer; override;
    function GetSR: Integer; override;
    procedure SetDevice(Ch: Integer); override;
    function GetDeviceInfo: TACSDeviceInfo; override;
    function GetTotalTime: Real; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetData(Buffer: Pointer; oBufferSize: Integer): Integer; override;
    procedure Init; override;
    procedure Flush; override;
  end;

var
  InputChannelsCount: Integer;
  OutputChannelsCount: Integer;

function GetAudioDeviceInfo(DevID: Integer; OutputDev: Boolean): TACSDeviceInfo;

implementation

var
  CrSecI, CrSecO: TRTLCriticalSection;
  
{$IFDEF MSWINDOWS}
{$I win32\acs_audio.inc}
{$ELSE}
{$I linux\acs_audio.inc}
{$ENDIF}

function TStdAudioOut.GetDeviceInfo: TACSDeviceInfo;
begin
  Result:=GetAudioDeviceInfo(FBaseChannel, True);
end;

function TStdAudioIn.GetDeviceInfo: TACSDeviceInfo;
begin
  Result:=GetAudioDeviceInfo(FBaseChannel, False);
end;

function TStdAudioIn.GetTotalTime: Real;
begin
  Result:=RecTime;
end;

constructor TStdAudioIn.Create;
begin
  inherited Create(AOwner);
  FBPS:=8;
  FChan:=1;
  FFreq:=8000;
  FSize:=-1;
  FRecTime:=600;
  BufferSize:=$1000;
  {$IFDEF MSWINDOWS}
  FBlocksCount:=4;
  {$ENDIF}
end;

function TStdAudioOut.GetDeviceCount: Integer;
begin
  Result:=OutputChannelsCount;
end;

initialization
  {$IFDEF MSWINDOWS}
  InitializeCriticalSection(CrSecI);
  InitializeCriticalSection(CrSecO);
  {$ENDIF}
  CountChannels;
  RegisterAudioOut('Wavemapper', TStdAudioOut, LATENCY);
  RegisterAudioIn('Wavemapper', TStdAudioIn, LATENCY);

finalization
  {$IFDEF MSWINDOWS}
  DeleteCriticalSection(CrSecI);
  DeleteCriticalSection(CrSecO);
  {$ENDIF}

end.