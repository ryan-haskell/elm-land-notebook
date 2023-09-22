const fs = require('fs/promises')
const os = require('os')
const path = require('path')
const express = require('express')
const cors = require('cors')
const { spawn } = require('child_process')
const app = express()

const port = process.env.PORT || 8007

app.use(cors())
app.use(express.json())

app.all('/api/compile', async (req, res) => {
  const elmCode = req.body.elmCode
  if (!elmCode) {
    return res.status(400).json({ message: 'No elm code received' })
  } else {
    const mainElmContents = `
module Main exposing (..)

import Html

main = Html.text ""

${elmCode}
    `.trim()

    const elmJsonContents =
      `{
  "type": "application",
  "source-directories": [
      "src"
  ],
  "elm-version": "0.19.1",
  "dependencies": {
      "direct": {
          "elm/browser": "1.0.2",
          "elm/core": "1.0.5",
          "elm/html": "1.0.0",
          "elm/http": "2.0.0",
          "elm/json": "1.1.3",
          "elm/url": "1.0.0",
          "elm-explorations/markdown": "1.0.0"
      },
      "indirect": {
          "elm/bytes": "1.0.8",
          "elm/file": "1.0.5",
          "elm/time": "1.0.0",
          "elm/virtual-dom": "1.0.3"
      }
  },
  "test-dependencies": {
      "direct": {},
      "indirect": {}
  }
}
`
    // Define filepaths
    const directory = path.join(os.tmpdir(), 'elm-notebook')
    const elmJsonFilepath = path.join(directory, 'elm.json')
    const mainElmFilepath = path.join(directory, 'src', 'Main.elm')
    const outJsFilepath = path.join(directory, 'out.js')

    // Create "elm.json" and "src/Main.elm" in temp directory
    await fs.mkdir(path.join(directory, 'src'), { recursive: true })
    await fs.writeFile(mainElmFilepath, mainElmContents, { encoding: 'utf-8' })
    await fs.writeFile(elmJsonFilepath, elmJsonContents, { encoding: 'utf-8' })

    // Run elm make
    let compilerResult = await new Promise((resolve) => {
      let elmMake = spawn(
        'elm', ['make', 'src/Main.elm', '--output=out.js'],
        { cwd: directory }
      )
      let error = ''
      elmMake.on('error', (err) => { console.error(err); resolve('error') })
      elmMake.stderr.on('data', (line) => error += line)
      elmMake.on('exit', async (code) => {
        console.log('exited', code)


        if (code === 0) {
          let compiledJs = await fs.readFile(outJsFilepath, { encoding: 'utf-8' })
          resolve({ tag: 'ok', code: compiledJs })
        } else {
          resolve({ tag: 'err', data: error })
        }
      })
    })

    res.json({ elmCode, compilerResult })
  }
})

app.listen(port, () => console.log(`😂 Ready at http://localhost:${port}`))