import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        
            if hasSeenOnboarding {
                AnimatedNavigationStack {
                    MainView()
                }
                .navigationBarBackButtonHidden()

            } else {
            NavigationStack {
                OnboardingView()
                    .navigationBarBackButtonHidden()

            }
            .navigationBarBackButtonHidden()
        }
    }
}

struct OnboardingView: View {


    var body: some View {
//        NavigationStack {
            OnboardingScreen1()
//        }

    }
}

struct OnboardingScreen1: View {
    var body: some View {
        VStack {
            Text("Welcome to the app!")
            NavigationLink("Next", destination: OnboardingScreen2())
        }
    }
}

struct OnboardingScreen2: View {
    var body: some View {
        VStack {
            Text("Learn about the features!")
            NavigationLink("Next", destination: OnboardingScreen3())
        }
    }
}

struct OnboardingScreen3: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        VStack {
            Button {
                hasSeenOnboarding = true
            } label: {
                Text("You're all set!")
            }

            
//                .onAppear {
//                    // Automatically mark onboarding as seen when it's completed
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                        hasSeenOnboarding = true
//                    }
//                }
        }
    }
}

struct MainView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    
    var body: some View {
//        NavigationStack {
            VStack {
                Text("Main View")
                NavigationLink("Next View", destination: SecondView())
            }
//            .onAppear {
//                // Automatically mark onboarding as seen when it's completed
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    hasSeenOnboarding = false
//                }
//            }
//        }
    }
}

struct SecondView: View {
    var body: some View {
//        NavigationStack {
            VStack {
                Text("Second View")
                NavigationLink("Next View", destination: ThirdView())
            }
//        }
    }
}

struct ThirdView: View {
    var body: some View {
//        NavigationStack {
            VStack {
                Text("Third View")
                NavigationLink("Next View", destination: FourthView())
            }
        }
//    }
}

struct FourthView: View {
    var body: some View {
//        NavigationStack {
            VStack {
                Text("Fourth View")
                NavigationLink("Next View", destination: FifthView())
            }
        }
//    }
}

struct FifthView: View {
    var body: some View {
        VStack {
            Text("Fifth View")
        }
    }
}
