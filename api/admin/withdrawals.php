<?php
/**
 * Admin Withdrawal Management Endpoint
 */

require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/functions.php';
require_once __DIR__ . '/../../config/auth.php';

$user = getAuthenticatedUser();
requireAdmin($user);

$db = getDatabaseConnection();

$action       = $_GET['action']        ?? 'list';
$withdrawalId = (int)($_GET['withdrawal_id'] ?? 0);

$allowedStatuses = ['pending', 'completed', 'rejected', 'all'];

try {
    switch ($action) {

        // ✅ NEW: View withdrawal details with bank information
        case 'details':
            if (!$withdrawalId) sendValidationError('Withdrawal ID is required.');

            $stmt = $db->prepare("
                SELECT wr.*, u.mystery_name, u.email, u.full_name, u.bank_name, u.account_number,
                       u.bank_code_type, u.bank_code_value
                FROM withdrawal_requests wr
                JOIN users u ON wr.user_id = u.id
                WHERE wr.id = ?
            ");
            $stmt->execute([$withdrawalId]);
            $withdrawal = $stmt->fetch();

            if (!$withdrawal) {
                sendError('Withdrawal not found.', 404);
            }

            sendResponse(true, 'Withdrawal details retrieved.', [
                'id'              => (int)$withdrawal['id'],
                'mystery_name'    => $withdrawal['mystery_name'],
                'email'           => $withdrawal['email'],
                'full_name'       => $withdrawal['full_name'],
                'bank_name'       => $withdrawal['bank_name'],
                'account_number'  => $withdrawal['account_number'],
                'account_name'    => $withdrawal['full_name'],
                'bank_code_type'  => $withdrawal['bank_code_type'],
                'bank_code_value' => $withdrawal['bank_code_value'],
                'amount'          => (float)$withdrawal['amount'],
                'fee'             => (float)$withdrawal['fee'],
                'net_amount'      => (float)$withdrawal['net_amount'],
                'status'          => $withdrawal['status'],
                'created_at'      => $withdrawal['created_at'],
                'completed_at'    => $withdrawal['completed_at'],
                'reference'       => $withdrawal['reference'],
            ]);
            break;

        case 'list':
            $statusFilter = $_GET['status'] ?? 'all';
            $page         = max(1, (int)($_GET['page'] ?? 1));
            $limit        = 20;
            $offset       = ($page - 1) * $limit;

            if (!in_array($statusFilter, $allowedStatuses, true)) sendValidationError('Invalid status filter.');

            $query  = "
                SELECT wr.id, u.mystery_name, u.bank_name, u.account_number,
                       u.bank_code_type, u.bank_code_value,
                       wr.amount, wr.fee, wr.net_amount,
                       wr.status, wr.reference, wr.created_at, wr.completed_at
                FROM withdrawal_requests wr
                JOIN users u ON wr.user_id = u.id
            ";
            $params = [];

            if ($statusFilter !== 'all') {
                $query   .= ' WHERE wr.status = ?';
                $params[] = $statusFilter;
            }

            $query   .= ' ORDER BY wr.created_at DESC LIMIT ? OFFSET ?';
            $params[] = $limit;
            $params[] = $offset;

            $stmt = $db->prepare($query);
            $stmt->execute($params);
            $withdrawals = $stmt->fetchAll();

            sendResponse(true, 'Withdrawal requests retrieved successfully.', [
                'withdrawals' => $withdrawals,
                'page'        => $page,
                'limit'       => $limit,
            ]);
            break;

        case 'approve':
            if (!$withdrawalId) sendValidationError('Withdrawal ID is required.');
            $body      = getJsonBody();
            $adminNote = trim($body['admin_note'] ?? '');

            $db->beginTransaction();

            // Lock the row to prevent concurrent approval
            $stmt = $db->prepare("SELECT * FROM withdrawal_requests WHERE id = ? AND status = 'pending' FOR UPDATE");
            $stmt->execute([$withdrawalId]);
            $withdrawal = $stmt->fetch();

            if (!$withdrawal) {
                $db->rollBack();
                sendError('Pending withdrawal request not found.', 404);
            }

            // Capture balance before deduction
            $stmt = $db->prepare('SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE');
            $stmt->execute([$withdrawal['user_id']]);
            $wallet = $stmt->fetch();

            if (!$wallet || (float)$wallet['balance'] < (float)$withdrawal['net_amount']) {
                $db->rollBack();
                sendError('Insufficient wallet balance. Cannot approve withdrawal.', 422);
            }

            $balanceBefore = (float)$wallet['balance'];
            $balanceAfter  = $balanceBefore - (float)$withdrawal['net_amount'];

            // Mark withdrawal completed
            $stmt = $db->prepare("UPDATE withdrawal_requests SET status = 'completed', admin_note = ?, completed_at = NOW() WHERE id = ?");
            $stmt->execute([$adminNote, $withdrawalId]);

            // Deduct net_amount (balance was already reduced at request time;
            // this records the final outflow against the reserved amount)
            $stmt = $db->prepare('UPDATE wallets SET balance = balance - ? WHERE user_id = ? AND balance >= ?');
            $stmt->execute([$withdrawal['net_amount'], $withdrawal['user_id'], $withdrawal['net_amount']]);

            if ($stmt->rowCount() === 0) {
                $db->rollBack();
                sendError('Insufficient wallet balance. Cannot approve withdrawal.', 422);
            }

            // Full ledger entry with balance snapshot
            $stmt = $db->prepare("
                INSERT INTO wallet_transactions
                    (user_id, type, amount_change, balance_before, balance_after, reference, description, status)
                VALUES (?, 'withdrawal_approved', ?, ?, ?, ?, ?, 'completed')
            ");
            $stmt->execute([
                $withdrawal['user_id'],
                -(float)$withdrawal['net_amount'],
                $balanceBefore,
                $balanceAfter,
                'Withdrawal Approved #' . $withdrawalId,
                'Withdrawal of ' . number_format((float)$withdrawal['net_amount'], 2) . ' approved by admin.',
            ]);

            // Notify influencer
            $stmt = $db->prepare("
                INSERT INTO notifications (user_id, title, body, type, created_at)
                VALUES (?, 'Withdrawal Approved', ?, 'withdrawal_approved', NOW())
            ");
            $stmt->execute([
                $withdrawal['user_id'],
                'Your withdrawal request for ' . number_format((float)$withdrawal['net_amount'], 2) . ' has been approved.',
            ]);

            $db->commit();
            sendResponse(true, 'Withdrawal request approved.');
            break;

        case 'reject':
            if (!$withdrawalId) sendValidationError('Withdrawal ID is required.');
            $body      = getJsonBody();
            $adminNote = trim($body['admin_note'] ?? '');

            $db->beginTransaction();

            $stmt = $db->prepare("SELECT * FROM withdrawal_requests WHERE id = ? AND status = 'pending' FOR UPDATE");
            $stmt->execute([$withdrawalId]);
            $withdrawal = $stmt->fetch();

            if (!$withdrawal) {
                $db->rollBack();
                sendError('Pending withdrawal request not found.', 404);
            }

            // Capture balance before refund
            $stmt = $db->prepare('SELECT balance FROM wallets WHERE user_id = ? FOR UPDATE');
            $stmt->execute([$withdrawal['user_id']]);
            $wallet = $stmt->fetch();
            $balanceBefore = (float)($wallet['balance'] ?? 0);
            $balanceAfter  = $balanceBefore + (float)$withdrawal['amount'];

            // Mark rejected
            $stmt = $db->prepare("UPDATE withdrawal_requests SET status = 'rejected', admin_note = ?, completed_at = NOW() WHERE id = ?");
            $stmt->execute([$adminNote, $withdrawalId]);

            // Refund original amount back to wallet
            $stmt = $db->prepare('UPDATE wallets SET balance = balance + ? WHERE user_id = ?');
            $stmt->execute([$withdrawal['amount'], $withdrawal['user_id']]);

            // Full ledger entry for the refund
            $stmt = $db->prepare("
                INSERT INTO wallet_transactions
                    (user_id, type, amount_change, balance_before, balance_after, reference, description, status)
                VALUES (?, 'withdrawal_rejected', ?, ?, ?, ?, ?, 'completed')
            ");
            $stmt->execute([
                $withdrawal['user_id'],
                (float)$withdrawal['amount'],
                $balanceBefore,
                $balanceAfter,
                'Withdrawal Rejected #' . $withdrawalId,
                'Withdrawal rejected by admin. Amount refunded to wallet.',
            ]);

            // Notify influencer
            $stmt = $db->prepare("
                INSERT INTO notifications (user_id, title, body, type, created_at)
                VALUES (?, 'Withdrawal Rejected', ?, 'withdrawal_rejected', NOW())
            ");
            $stmt->execute([
                $withdrawal['user_id'],
                'Your withdrawal request for ' . number_format((float)$withdrawal['amount'], 2) . ' was rejected. Funds have been returned to your wallet.',
            ]);

            $db->commit();
            sendResponse(true, 'Withdrawal request rejected and funds refunded.');
            break;

        default:
            sendError('Invalid action.', 400);
            break;
    }

} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    error_log('Admin Withdrawal Management Error: ' . $e->getMessage());
    sendError('An error occurred during withdrawal management.');
}