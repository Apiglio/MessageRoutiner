unit unit_writescreen;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;

var
  pixel_array:array[0..255]of array[0..15] of word;

implementation


initialization
  {
  pixel_array[65]:=(384,960,2016,3696,7224,14364,12300,12300,12300,
                    16380,16380,12300,12300,12300,12300,12300);
  pixel_array[66]:=(2046,8188,7692,14348,14348,6156,7180,4092,4092,
                    7180,14348,14348,14348,7692,8188,2046);
  }
end.

