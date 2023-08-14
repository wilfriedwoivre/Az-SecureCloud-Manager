function Get-IniContent ($filePath) {
    $ini = @{}
    switch -regex -file $FilePath {
        “^\[(.+)\]” { # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” { # Comment
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value.trim()
        }
        “(.+?)\s*=(.*)” { # Key
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value.trim()
        }
    }
    return $ini
}

function Set-EnvVariablesFromEnvFile($envFile) {
    $envVars = Get-Content $envFile
    $envVars | ForEach-Object {
        $name, $value = $_.split('=')
        set-content env:\$name $value
    }
}
