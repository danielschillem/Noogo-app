import { Component, type ErrorInfo, type ReactNode } from 'react';
import { RefreshCw, AlertTriangle } from 'lucide-react';

interface Props {
    children: ReactNode;
}

interface State {
    hasError: boolean;
    error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error: Error): State {
        return { hasError: true, error };
    }

    componentDidCatch(error: Error, info: ErrorInfo) {
        console.error('[ErrorBoundary]', error, info.componentStack);
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="min-h-screen flex items-center justify-center bg-gray-50 p-6">
                    <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 max-w-md w-full text-center">
                        <div className="flex justify-center mb-4">
                            <div className="w-14 h-14 rounded-2xl bg-red-50 flex items-center justify-center">
                                <AlertTriangle className="h-7 w-7 text-red-500" />
                            </div>
                        </div>
                        <h1 className="text-xl font-bold text-gray-900 mb-2">Une erreur est survenue</h1>
                        <p className="text-sm text-gray-500 mb-6">
                            {this.state.error?.message ?? 'Erreur inattendue'}
                        </p>
                        <button
                            onClick={() => window.location.reload()}
                            className="inline-flex items-center gap-2 px-5 py-2.5 bg-orange-500 text-white rounded-xl text-sm font-medium hover:bg-orange-600 transition-colors"
                        >
                            <RefreshCw className="h-4 w-4" />
                            Recharger la page
                        </button>
                    </div>
                </div>
            );
        }
        return this.props.children;
    }
}
