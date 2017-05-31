#!/usr/bin/env ruby

require 'rubygems'
require 'ethereum.rb'
require 'terminfo'
require 'colorize'

@parity = Ethereum::IpcClient.new '/home/user/.local/share/io.parity.ethereum/jsonrpc.ipc', false

def parse_result response
  result = response['result']
end

blocks = {}
previous = -999
loop do
  height = TermInfo.screen_size.first - 5
  width = TermInfo.screen_size.last - 12
  delay = 15
  block16 = parse_result @parity.eth_block_number
  current = block16.to_i 16
  if previous < 0
    previous = current - 16
  end
  while previous <= current
    block = parse_result @parity.eth_get_block_by_number(previous, false)
    blocks[previous] = {
      number: block["number"].to_i(16),
      gasLimit: block["gasLimit"].to_i(16),
      gasUsed: block["gasUsed"].to_i(16),
      utilization: (block["gasUsed"].to_i(16).to_f / block["gasLimit"].to_i(16).to_f)
    }
    previous += 1
  end
  previous = current
  system "clear" or system "cls"
  printf "Ethereum networt gas usage visualization\t["
  printf "###".light_green
  printf "   ]: low\n"
  printf "========================================\t["
  printf "###".light_green
  printf "##".light_yellow
  printf " ]: high\n"
  printf "                                        \t["
  printf "###".light_green
  printf "##".light_yellow
  printf "#".light_red
  printf "]: full\n\n"
  blocks.each do | n, b |
    if n > current - height
      num = n.to_s
      util = b[:utilization] * width.to_f
      printf "#{num}: ["
      for i in 0..width
        if i <= util.round
          if i < width * 0.50
            printf "#".light_green
          elsif i < width * 0.90
            printf "#".light_yellow
          else
            printf "#".light_red
          end
        else
          printf " ".light_black
        end
      end
      printf "]\n"
    end
  end
  sleep delay
end
