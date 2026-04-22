<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('delivery_address')->nullable()->after('table_number');
            $table->decimal('delivery_lat', 10, 7)->nullable()->after('delivery_address');
            $table->decimal('delivery_lng', 10, 7)->nullable()->after('delivery_lat');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['delivery_address', 'delivery_lat', 'delivery_lng']);
        });
    }
};
