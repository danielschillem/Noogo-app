<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('restaurants', function (Blueprint $table) {
            $table->string('license_plan', 50)->nullable()->after('qr_code');
            $table->string('license_status', 20)->default('active')->after('license_plan');
            $table->timestamp('license_expires_at')->nullable()->after('license_status');
            $table->unsignedInteger('license_max_staff')->nullable()->after('license_expires_at');
        });
    }

    public function down(): void
    {
        Schema::table('restaurants', function (Blueprint $table) {
            $table->dropColumn([
                'license_plan',
                'license_status',
                'license_expires_at',
                'license_max_staff',
            ]);
        });
    }
};

