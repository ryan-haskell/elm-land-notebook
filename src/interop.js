// This returns the flags passed into your Elm application
export const flags = async ({ env }) => {
  return {}
}

// This function is called once your Elm app is running
export const onReady = ({ app, env }) => {
  app.ports.sendToElmCompilerPort.subscribe(({ elmCode }) => {
    console.log(`
module Main exposing (..)

import Html exposing (..)


main =
    text ""

${elmCode}
    `.trim())
  })
}