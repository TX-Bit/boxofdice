package com.example.boxofdice

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.boxofdice.ui.AppLocaleProvider
import com.example.boxofdice.ui.GameScreen
import com.example.boxofdice.ui.theme.BoardTheme
import com.example.boxofdice.ui.theme.GameTheme
import com.example.boxofdice.ui.theme.LocalBoardTheme
import com.example.boxofdice.viewmodel.GameViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            GameTheme {
                val vm: GameViewModel = viewModel()
                val settings by vm.settings.collectAsStateWithLifecycle()
                AppLocaleProvider(settings.language) {
                    CompositionLocalProvider(
                        LocalBoardTheme provides BoardTheme.palette(settings.theme)
                    ) {
                        GameScreen(viewModel = vm)
                    }
                }
            }
        }
    }
}
