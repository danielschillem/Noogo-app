import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, Loader2, ArrowLeft, Copy, Check, CheckCircle } from 'lucide-react';
import { authApi } from '../../services/api';

export default function ForgotPasswordPage() {
    const [email, setEmail] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [resetToken, setResetToken] = useState('');
    const [copied, setCopied] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        if (!email.trim()) { setError('Veuillez entrer votre adresse email'); return; }

        setIsLoading(true);
        try {
            const res = await authApi.forgotPassword(email.trim());
            const token = res.data?.data?.reset_token;
            if (token) setResetToken(token);
        } catch (err: unknown) {
            const axiosError = err as { response?: { data?: { message?: string } } };
            setError(axiosError.response?.data?.message ?? 'Une erreur est survenue');
        } finally {
            setIsLoading(false);
        }
    };

    const handleCopy = async () => {
        if (!resetToken) return;
        await navigator.clipboard.writeText(resetToken);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100 px-4">
            <div className="max-w-md w-full">
                {/* Logo */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-16 h-16 bg-orange-500 rounded-2xl mb-4">
                        <span className="text-white font-bold text-3xl">N</span>
                    </div>
                    <h1 className="text-2xl font-bold text-gray-900">Mot de passe oublié</h1>
                    <p className="text-gray-600 mt-2">
                        {resetToken
                            ? 'Votre code de réinitialisation est prêt'
                            : 'Entrez votre email pour recevoir un code de réinitialisation'}
                    </p>
                </div>

                <div className="bg-white rounded-2xl shadow-xl p-8">
                    {!resetToken ? (
                        <form onSubmit={handleSubmit} className="space-y-6">
                            {error && (
                                <div className="bg-red-50 text-red-600 px-4 py-3 rounded-lg text-sm">
                                    {error}
                                </div>
                            )}

                            <div>
                                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                                    Adresse email
                                </label>
                                <div className="relative">
                                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                                    <input
                                        id="email"
                                        type="email"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        required
                                        className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent transition-all"
                                        placeholder="votre@email.com"
                                    />
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={isLoading}
                                className="w-full bg-orange-500 text-white py-3 rounded-lg font-medium hover:bg-orange-600 focus:ring-4 focus:ring-orange-200 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            >
                                {isLoading ? (
                                    <>
                                        <Loader2 className="h-5 w-5 animate-spin" />
                                        Envoi en cours...
                                    </>
                                ) : (
                                    'Envoyer le code'
                                )}
                            </button>
                        </form>
                    ) : (
                        <div className="space-y-6">
                            <div className="bg-green-50 border border-green-200 rounded-xl p-4">
                                <p className="text-sm text-green-700 font-medium mb-2 flex items-center gap-1.5">
                                    <CheckCircle className="h-4 w-4" /> Code généré avec succès
                                </p>
                                <p className="text-xs text-green-600">
                                    Copiez ce code et utilisez-le pour réinitialiser votre mot de passe. Il expire dans 60 minutes.
                                </p>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">
                                    Votre code de réinitialisation
                                </label>
                                <div className="flex gap-2">
                                    <input
                                        type="text"
                                        readOnly
                                        value={resetToken}
                                        className="flex-1 px-3 py-2 border border-gray-200 rounded-lg bg-gray-50 text-sm font-mono text-gray-700 truncate"
                                    />
                                    <button
                                        type="button"
                                        onClick={handleCopy}
                                        className="flex items-center gap-1 px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 text-sm text-gray-600 transition-all"
                                    >
                                        {copied ? (
                                            <><Check className="h-4 w-4 text-green-500" /> Copié</>
                                        ) : (
                                            <><Copy className="h-4 w-4" /> Copier</>
                                        )}
                                    </button>
                                </div>
                            </div>

                            <Link
                                to="/reset-password"
                                className="block w-full text-center bg-orange-500 text-white py-3 rounded-lg font-medium hover:bg-orange-600 transition-all"
                            >
                                Réinitialiser mon mot de passe →
                            </Link>
                        </div>
                    )}

                    <div className="mt-6 flex items-center justify-center gap-1 text-sm text-gray-600">
                        <ArrowLeft className="h-4 w-4" />
                        <Link to="/login" className="text-orange-500 hover:text-orange-600 font-medium">
                            Retour à la connexion
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}
